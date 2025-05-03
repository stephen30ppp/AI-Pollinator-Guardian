import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/design_tokens.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

class SightingDetailSheet extends StatelessWidget {
  final Map<String, dynamic> sighting;
  final VoidCallback onClose;
  
  const SightingDetailSheet({
    super.key, 
    required this.sighting,
    required this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3, // 初始高度为30%
      minChildSize: 0.15,    // 最小高度
      maxChildSize: 0.8,     // 最大高度为80%
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // 顶部拖动条
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // 主要内容
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和关闭按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sighting['commonName'] ?? 'Unknown Pollinator',
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                      
                      // 科学名称
                      if (sighting['scientificName'] != null)
                        Text(
                          sighting['scientificName'],
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      
                      const SizedBox(height: DesignTokens.m),
                      
                      // 图片和详情
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 图片
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                            child: Image.network(
                              sighting['imageUrl'] ?? 'https://via.placeholder.com/150',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          const SizedBox(width: DesignTokens.m),
                          
                          // 详情
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  context,
                                  Icons.access_time,
                                  'Spotted: ${sighting['timeAgo'] ?? 'Recently'}',
                                ),
                                const SizedBox(height: DesignTokens.xs),
                                _buildDetailRow(
                                  context,
                                  Icons.location_on,
                                  'Distance: ${sighting['distance'] ?? 'Unknown'}',
                                ),
                                const SizedBox(height: DesignTokens.xs),
                                _buildDetailRow(
                                  context,
                                  Icons.nature_people,
                                  'Nearby: ${sighting['nearbyCount'] ?? 0} sightings',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: DesignTokens.m),
                      
                      // 描述
                      if (sighting['description'] != null) ...[
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: DesignTokens.xs),
                        Text(
                          sighting['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      
                      const SizedBox(height: DesignTokens.l),
                      
                      // 动作按钮
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                // 获取方向的实现
                              },
                            ),
                          ),
                          const SizedBox(width: DesignTokens.m),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.info_outline),
                              label: const Text('More Info'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                // 显示更多信息的实现
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 额外的详细信息（只在拖拽展开时显示）
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: DesignTokens.m),
                      
                      // 保护信息
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conservation Status',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: DesignTokens.xs),
                              _buildStatusIndicator(context, 'Population Trend', 0.7),
                              const SizedBox(height: DesignTokens.xs),
                              _buildStatusIndicator(context, 'Habitat Loss', 0.4),
                              const SizedBox(height: DesignTokens.xs),
                              _buildStatusIndicator(context, 'Pollination Rate', 0.9),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: DesignTokens.m),
                      
                      // 图片库
                      Text(
                        'Gallery',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: DesignTokens.xs),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5, // 示例图片数量
                          itemBuilder: (context, index) {
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: DesignTokens.s),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    sighting['imageUrl'] ?? 'https://via.placeholder.com/120',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: DesignTokens.l),
                      
                      // 社区行动
                      ElevatedButton.icon(
                        icon: const Icon(Icons.eco),
                        label: const Text('Join Conservation Effort'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: () {
                          // 加入保护行动的实现
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIndicator(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            value > 0.6 ? AppColors.primaryColor : AppColors.accentColor,
          ),
        ),
      ],
    );
  }
}