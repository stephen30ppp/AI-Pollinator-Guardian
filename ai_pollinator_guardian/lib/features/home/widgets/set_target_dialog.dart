import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/constants/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetTargetDialog extends StatefulWidget {
  final String targetType;
  final int currentTarget;
  final Function(int) onTargetSet;

  const SetTargetDialog({
    Key? key,
    required this.targetType,
    required this.currentTarget,
    required this.onTargetSet,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required int currentTarget,
    required Function(int) onTargetSet,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetTargetDialog(
        targetType: targetType,
        currentTarget: currentTarget,
        onTargetSet: onTargetSet,
      ),
    );
  }

  @override
  State<SetTargetDialog> createState() => _SetTargetDialogState();
}

class _SetTargetDialogState extends State<SetTargetDialog> {
  late TextEditingController _targetController;
  int _selectedPreset = 0;
  final List<int> _presets = [5, 10, 20, 30];

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: widget.currentTarget.toString());
    
    // Find closest preset or set to custom
    final closestPresetIndex = _presets.indexOf(
      _presets.contains(widget.currentTarget) 
          ? widget.currentTarget 
          : _presets.first
    );
    _selectedPreset = closestPresetIndex != -1 ? closestPresetIndex : -1;
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _handlePresetTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = index;
      _targetController.text = _presets[index].toString();
    });
  }

  void _handleCustomInput(String value) {
    if (value.isEmpty) return;
    
    final customValue = int.tryParse(value) ?? 0;
    if (_presets.contains(customValue)) {
      setState(() {
        _selectedPreset = _presets.indexOf(customValue);
      });
    } else {
      setState(() {
        _selectedPreset = -1; // Custom value
      });
    }
  }

  void _saveTarget() {
    final target = int.tryParse(_targetController.text) ?? widget.currentTarget;
    widget.onTargetSet(target);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.l,
              vertical: DesignTokens.m,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: DesignTokens.m),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Title
                Text(
                  'Set ${widget.targetType} Target',
                  style: DesignTokens.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.xs),
                Text(
                  'Choose how many ${widget.targetType.toLowerCase()} you want to achieve weekly.',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.l),
                
                // Preset options
                _buildSectionTitle('Quick Select', theme),
                const SizedBox(height: DesignTokens.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _presets.length,
                    (index) => _buildPresetButton(index, theme),
                  ),
                ),
                const SizedBox(height: DesignTokens.l),
                
                // Custom input
                _buildSectionTitle('Custom Target', theme),
                const SizedBox(height: DesignTokens.s),
                TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  onChanged: _handleCustomInput,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3), // Maximum 3 digits (up to 999)
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter target',
                    suffixText: widget.targetType,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.l,
                      vertical: DesignTokens.m,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.l),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.l,
                          vertical: DesignTokens.s,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.m),
                    ElevatedButton(
                      onPressed: _saveTarget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.l,
                          vertical: DesignTokens.s,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: DesignTokens.labelMedium.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPresetButton(int index, ThemeData theme) {
    final isSelected = _selectedPreset == index;
    
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: DesignTokens.animationFast,
      child: GestureDetector(
        onTap: () => _handlePresetTap(index),
        child: AnimatedContainer(
          duration: DesignTokens.animationNormal,
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryColor 
                : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primaryColor 
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              _presets[index].toString(),
              style: DesignTokens.titleMedium.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}