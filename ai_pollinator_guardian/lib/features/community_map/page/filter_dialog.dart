// lib/features/community_map/pages/filter_dialog.dart

import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final String? initialSpecies;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialLocation;
  final Function(String? species, DateTime? startDate, DateTime? endDate, String? location) onApplyFilters;

  const FilterDialog({
    Key? key,
    this.initialSpecies,
    this.initialStartDate,
    this.initialEndDate,
    this.initialLocation,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TextEditingController _speciesController;
  late TextEditingController _locationController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _speciesController = TextEditingController(text: widget.initialSpecies);
    _locationController = TextEditingController(text: widget.initialLocation);
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("设置过滤条件"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _speciesController,
              decoration: const InputDecoration(labelText: "物种名称"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "位置（可选）"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                  });
                }
              },
              child: Text(_startDate == null ? "选择开始日期" : "开始日期: ${_startDate!.toLocal()}"),
            ),
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                }
              },
              child: Text(_endDate == null ? "选择结束日期" : "结束日期: ${_endDate!.toLocal()}"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            widget.onApplyFilters(
              _speciesController.text.isNotEmpty ? _speciesController.text : null,
              _startDate,
              _endDate,
              _locationController.text.isNotEmpty ? _locationController.text : null,
            );
            Navigator.pop(context);
          },
          child: const Text("应用"),
        ),
      ],
    );
  }
}
