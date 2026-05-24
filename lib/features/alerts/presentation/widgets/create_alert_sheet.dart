import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/alert_cubit.dart';
import '../cubit/alert_state.dart';

class CreateAlertSheet extends StatefulWidget {
  final String assetName;
  final double lastPrice;
  final String? instrumentId;

  const CreateAlertSheet({
    super.key,
    required this.assetName,
    required this.lastPrice,
    this.instrumentId,
  });

  @override
  State<CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<CreateAlertSheet> {
  late TextEditingController _priceController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
  }

  void _showError(String message) {
    // Dismiss keyboard so user can see the error clearly at the top
    FocusScope.of(context).unfocus();
    
    setState(() {
      _errorMessage = message;
    });
    // Auto-hide error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertCubit, AlertState>(
      builder: (context, state) {
        final cubit = context.read<AlertCubit>();

        String currentConditionLabel = state.selectedTab == "Price"
            ? state.priceCondition
            : (state.selectedTab == "Charge %" ? state.gainCondition : state.volumeCondition);

        return Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF131517),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Center(child: Text("Create Alert", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 24),
              Text(widget.assetName, style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text(state.selectedTab == "Price" ? "Last Price ${widget.lastPrice.toStringAsFixed(2)}" : "Last Change", 
                   style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              _buildTabPicker(cubit, state.selectedTab),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _showConditionPicker(context, cubit, state),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(currentConditionLabel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const Icon(Icons.filter_list, color: Color(0xFF8B5CF6), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildInputArea(state.selectedTab, widget.lastPrice),
              const SizedBox(height: 16),
              if (state.selectedTab == "Volume") ...[
                _buildCustomToggle("Recurring Alert", state.recurringAlert, cubit.toggleRecurring),
                _buildCustomToggle("Send me a reminder 1 trading day before", state.tradingReminder, cubit.toggleReminder),
              ] else ...[
                _buildCustomToggle("Send an email notification", state.emailNotification, cubit.toggleEmail),
              ],
              const SizedBox(height: 32),
              _buildCreateButton(context, cubit, state),
            ],
          ),
        );
      },
    );
  }

  void _showConditionPicker(BuildContext context, AlertCubit cubit, AlertState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (pickerContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D21),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choose condition", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10, height: 32),
            if (state.selectedTab == "Price") ...[
              _buildPickerOption(context, cubit, "Move Above", state.priceCondition == "Move Above"),
              _buildPickerOption(context, cubit, "Move Below", state.priceCondition == "Move Below"),
            ] else if (state.selectedTab == "Charge %") ...[
              _buildPickerOption(context, cubit, "Gain", state.gainCondition == "Gain"),
              _buildPickerOption(context, cubit, "Loses", state.gainCondition == "Loses"),
              _buildPickerOption(context, cubit, "Gain / Loses", state.gainCondition == "Gain / Loses"),
            ] else ...[
              _buildPickerOption(context, cubit, "Exceeds", state.volumeCondition == "Exceeds"),
              _buildPickerOption(context, cubit, "Below", state.volumeCondition == "Below"),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(BuildContext context, AlertCubit cubit, String title, bool isSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Icon(isSelected ? Icons.check_circle_outline : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF8B5CF6) : Colors.white24),
      onTap: () {
        cubit.updateCondition(title);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTabPicker(AlertCubit cubit, String selectedTab) {
    return Row(
      children: ["Price", "Charge %", "Volume"].map((tab) {
        bool isSelected = selectedTab == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () => cubit.updateTab(tab),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.05),
                border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(tab, style: TextStyle(color: isSelected ? Colors.white : Colors.grey))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputArea(String selectedTab, double lastPrice) {
    return TextField(
      controller: _priceController,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintText: selectedTab == "Charge %" ? "13" : lastPrice.toStringAsFixed(2),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }

  Widget _buildCustomToggle(String title, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank, color: value ? const Color(0xFF8B5CF6) : Colors.white24),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, AlertCubit cubit, AlertState state) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF4C3BB1), Color(0xFF3B2E8A)]),
      ),
      child: ElevatedButton(
        onPressed: () {
          final priceText = _priceController.text.trim();
          if (priceText.isEmpty) {
            _showError("Please enter a value");
            return;
          }

          double? targetPrice = double.tryParse(priceText);
          if (targetPrice == null) {
            _showError("Invalid value format");
            return;
          }

          // Validation: Alert price cannot be the same as current market price
          if (state.selectedTab == "Price" && targetPrice == widget.lastPrice) {
            _showError("Alert price cannot be the same as the current market price (${widget.lastPrice.toStringAsFixed(2)})");
            return;
          }
          
          String type = "price_above";
          if (state.selectedTab == "Price") {
            type = state.priceCondition == "Move Below" ? "price_below" : "price_above";
          } else if (state.selectedTab == "Charge %") {
             type = state.gainCondition == "Loses" ? "percent_down" : "percent_up";
          } else {
             type = state.volumeCondition == "Below" ? "volume_below" : "volume_above";
          }
          
          DateTime expiresAt = DateTime.now().add(const Duration(days: 30));
          
          cubit.createAlert(widget.instrumentId ?? widget.assetName, targetPrice, type, expiresAt: expiresAt);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text("Create", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}