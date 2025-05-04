import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/constants/design_tokens.dart';

enum SaveStage {
  preparing,
  uploadingImages,
  savingData,
  complete,
  error
}

class SaveProgressOverlay extends StatelessWidget {
  final double progress;
  final SaveStage stage;
  final String? errorMessage;
  final VoidCallback? onClose;
  
  const SaveProgressOverlay({
    super.key,
    required this.progress,
    required this.stage,
    this.errorMessage,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = stage == SaveStage.complete;
    final bool isError = stage == SaveStage.error;
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedContainer(
            duration: DesignTokens.animationNormal,
            curve: Curves.easeInOut,
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show animated check or error icon when complete
                if (isComplete || isError)
                  _buildResultIcon(isError)
                else
                  _buildProgressIndicator(progress),
                
                const SizedBox(height: 24),
                
                // Status text
                Text(
                  _getStageText(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Substatus text
                Text(
                  _getSubText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Show error message if present
                if (isError && errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                ],
                
                // Close button appears when complete or on error
                if (isComplete || isError) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError 
                          ? Colors.red[600] 
                          : AppColors.primaryColor,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      isError ? 'Close' : 'Awesome!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
              
              // Percentage text
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultIcon(bool isError) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isError ? Colors.red[50] : Colors.green[50],
      ),
      child: Center(
        child: Icon(
          isError ? Icons.error_outline : Icons.check_circle,
          size: 70,
          color: isError ? Colors.red : Colors.green,
        ),
      ),
    );
  }
  
  String _getStageText() {
    switch (stage) {
      case SaveStage.preparing:
        return 'Preparing Your Garden Profile';
      case SaveStage.uploadingImages:
        return 'Uploading Garden Images';
      case SaveStage.savingData:
        return 'Saving Analysis Data';
      case SaveStage.complete:
        return 'Garden Profile Saved!';
      case SaveStage.error:
        return 'Oops! Something Went Wrong';
    }
  }
  
  String _getSubText() {
    switch (stage) {
      case SaveStage.preparing:
        return 'Getting everything ready...';
      case SaveStage.uploadingImages:
        return 'Uploading your garden photos to the cloud';
      case SaveStage.savingData:
        return 'Saving your pollinator analysis and recommendations';
      case SaveStage.complete:
        return 'Your garden profile has been successfully saved. You can view it anytime in your history.';
      case SaveStage.error:
        return 'We encountered an issue while saving your garden profile.';
    }
  }
}