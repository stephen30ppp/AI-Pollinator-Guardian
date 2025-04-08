// lib/features/community_map/pages/community_map_screen.dart

import 'package:ai_pollinator_guardian/features/community_map/community_map_provider.dart';
import 'package:ai_pollinator_guardian/features/community_map/page/filter_dialog.dart';
import 'package:ai_pollinator_guardian/models/pollinator_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({Key? key}) : super(key: key);

  @override
  _CommunityMapScreenState createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // 默认中心位置为吉隆坡
  static const LatLng _kualaLumpur = LatLng(3.1390, 101.6869);

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // 延迟到当前帧结束后调用数据加载
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<CommunityMapProvider>();
        provider.fetchPollinators(); // 此处调用 Provider 中的数据加载方法改名为 fetchPollinators()
      });
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityMapProvider>();
    _markers = _buildMarkers(provider.pollinators);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map of Community Pollinators"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  return FilterDialog(
                    initialSpecies: provider.speciesFilter,
                    initialStartDate: provider.startDateFilter,
                    initialEndDate: provider.endDateFilter,
                    initialLocation: provider.locationFilter,
                    onApplyFilters: (species, startDate, endDate, location) {
                      provider.setFilters(
                        species: species,
                        startDate: startDate,
                        endDate: endDate,
                        location: location,
                      );
                    },
                  );
                },
              );
            },
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.moveCamera(
                  CameraUpdate.newLatLngZoom(_kualaLumpur, 12),
                );
              },
              initialCameraPosition: const CameraPosition(
                target: _kualaLumpur,
                zoom: 12,
              ),
              markers: _markers,
            ),
    );
  }

  Set<Marker> _buildMarkers(List<PollinatorModel> pollinators) {
    return pollinators.map((model) {
      // 从 additionalInfo 提取 'location' (GeoPoint)
      final geo = model.additionalInfo['location'];
      // 判断类型是否为 GeoPoint，然后转换为 LatLng
      if (geo is GeoPoint) {
        return Marker(
          markerId: MarkerId(model.id),
          position: LatLng(geo.latitude, geo.longitude),
          infoWindow: InfoWindow(
            title: model.commonName,
            snippet:
                "${model.scientificName}\nStatus: ${model.conservationStatus}\n${model.description}",
          ),
        );
      } else {
        // 如果没有有效的地理位置信息，则不生成 Marker
        return null;
      }
    }).whereType<Marker>().toSet();
  }
}
