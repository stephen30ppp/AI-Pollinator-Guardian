import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/design_tokens.dart';

class TargetSettingDialog extends StatefulWidget {
  final String title;
  final int currentValue;
  final int initialTarget;
  final Function(int) onSave;

  const TargetSettingDialog({
    super.key,
    required this.title,
    required this.currentValue,
    required this.initialTarget,
    required this.onSave,
  });

  @override
  State<TargetSettingDialog> createState() => _TargetSettingDialogState();
}

class _TargetSettingDialogState extends State<TargetSettingDialog> {
  late int _selectedTarget;
  final TextEditingController _customTargetController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  bool _showValidationError = false;

  // Common target presets
  final List<int> _presets = [5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget;
    _customTargetController.text = _selectedTarget.toString();

    // Select preset if initial value matches
    if (!_presets.contains(_selectedTarget)) {
        // If initial target is not a preset, focus the custom field
        WidgetsBinding.instance.addPostFrameCallback((_) {
         FocusScope.of(context).requestFocus(_customFocusNode);
         _customTargetController.selectAll();
        });
    }
  }

  @override
  void dispose() {
    _customTargetController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  void _selectPreset(int value) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTarget = value;
      _customTargetController.text = value.toString();
      _showValidationError = false; // Clear error on preset selection
       if (_customFocusNode.hasFocus) {
        _customFocusNode.unfocus(); // Unfocus custom field when preset is tapped
      }
    });
  }

  void _updateCustomTarget(String value) {
     final int? intValue = int.tryParse(value);
     setState(() {
        if (intValue != null && intValue > 0) {
           _selectedTarget = intValue;
           _showValidationError = false;
        } else {
          // Keep previous valid target, but show error if input is invalid
          _showValidationError = value.isNotEmpty;
        }
        // Keep selected preset visual state consistent only if value matches
        if (!_presets.contains(intValue)) {
           // Deselect presets visually if custom doesn't match
        }
     });
  }

  void _saveTarget() {
    final int? finalTarget = int.tryParse(_customTargetController.text);
    if (finalTarget != null && finalTarget > 0) {
      HapticFeedback.mediumImpact();
      widget.onSave(finalTarget);
      Navigator.of(context).pop();
    } else {
      HapticFeedback.heavyImpact(); // Error feedback
      setState(() {
        _showValidationError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      title: Text(widget.title, style: DesignTokens.titleMedium),
      content: SingleChildScrollView( // Avoid overflow if many presets/long text
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a preset or enter a custom target:',
              style: DesignTokens.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: DesignTokens.m),

            // Preset Buttons (using ChoiceChip for better semantics/selection state)
            Wrap(
              spacing: DesignTokens.s,
              runSpacing: DesignTokens.s,
              children: _presets.map((preset) {
                final bool isSelected = _selectedTarget == preset && !_customFocusNode.hasFocus;
                return ChoiceChip(
                  label: Text('$preset'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _selectPreset(preset);
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: isSelected ? BorderSide.none : BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                   ),
                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.l),

            // Custom Input Field
            TextField(
              controller: _customTargetController,
              focusNode: _customFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Custom Target',
                hintText: 'Enter a positive number',
                prefixIcon: const Icon(Icons.edit_rounded),
                border: const OutlineInputBorder(
                   borderRadius: BorderRadius.all(Radius.circular(DesignTokens.radiusMedium))
                ),
                errorText: _showValidationError ? 'Please enter a valid number > 0' : null,
                // Highlight border if focused or error
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                  borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.radiusMedium))
                ),
                 errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.error, width: 1.5),
                   borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.radiusMedium))
                ),
                 focusedErrorBorder: OutlineInputBorder(
                   borderSide: BorderSide(color: colorScheme.error, width: 2.0),
                   borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.radiusMedium))
                 ),
              ),
              onChanged: _updateCustomTarget,
              onTap: () {
                // Select all text when tapped for easy replacement
                 _customTargetController.selectAll();
                 // Clear visual selection from presets when custom field focused
                 if (_presets.contains(_selectedTarget)){
                    setState(() {}); // Trigger rebuild to deselect chip
                 }
              },
              onSubmitted: (_) => _saveTarget(), // Allow saving via keyboard action
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
             HapticFeedback.lightImpact();
             Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton.tonal( // Use tonal for primary action
          onPressed: _saveTarget,
          child: const Text('Save Target'),
          // Add animation/style?
        ),
      ],
    );
  }
}

// Helper extension for TextField controller
extension SelectAllExtension on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}