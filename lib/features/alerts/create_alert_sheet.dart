import 'package:flutter/material.dart';

class CreateAlertSheet extends StatefulWidget {
  final String assetName; 
  final double lastPrice;

  const CreateAlertSheet({
    super.key,
    required this.assetName,
    required this.lastPrice,
  });

  @override
  State<CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<CreateAlertSheet> {
  String _selectedTab = "Price"; 
  bool _emailNotification = true;
  bool _recurringAlert = false;
  bool _tradingReminder = false;

  // Track the chosen condition for each tab
  String _priceCondition = "Move Above";
  String _gainCondition = "Gain";
  String _volumeCondition = "Exceeds";

  // --- THE CONDITION PICKER MENU (IMAGE 9/10) ---
  void _showConditionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D21),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Choose condition",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            
            // Logic to show different options based on the active tab
            if (_selectedTab == "Price") ...[
              _buildPickerOption("Move Above", _priceCondition == "Move Above"),
              _buildPickerOption("Move Below", _priceCondition == "Move Below"),
            ] else if (_selectedTab == "Charge %") ...[
              _buildPickerOption("Gain", _gainCondition == "Gain"),
              _buildPickerOption("Loses", _gainCondition == "Loses"),
              _buildPickerOption("Gain / Loses", _gainCondition == "Gain / Loses"),
            ] else ...[
              _buildPickerOption("Exceeds", _volumeCondition == "Exceeds"),
              _buildPickerOption("Below", _volumeCondition == "Below"),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(String title, bool isSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Icon(
        isSelected ? Icons.check_circle_outline : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFF8B5CF6) : Colors.white24,
      ),
      onTap: () {
        setState(() {
          if (_selectedTab == "Price") _priceCondition = title;
          if (_selectedTab == "Charge %") _gainCondition = title;
          if (_selectedTab == "Volume") _volumeCondition = title;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which label to show at the top of the input
    String currentConditionLabel;
    if (_selectedTab == "Price") currentConditionLabel = _priceCondition;
    else if (_selectedTab == "Charge %") currentConditionLabel = _gainCondition;
    else currentConditionLabel = _volumeCondition;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Keeps UI above keyboard
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
          const SizedBox(height: 20),
          const Center(child: Text("Create Alert", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          
          const SizedBox(height: 24),
          Text(widget.assetName, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(_selectedTab == "Price" ? "Last Price ${widget.lastPrice}" : "Last Change", 
               style: const TextStyle(color: Colors.grey, fontSize: 13)),
          
          const SizedBox(height: 20),
          _buildTabPicker(),
          
          const SizedBox(height: 24),
          
          // --- CLICKABLE LABEL TO OPEN PICKER ---
          GestureDetector(
            onTap: _showConditionPicker,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentConditionLabel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Icon(Icons.filter_list, color: Color(0xFF8B5CF6), size: 20),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          _buildInputArea(),
          
          const SizedBox(height: 16),
          
          // Show different checkboxes based on the tab (Image 8 logic)
          if (_selectedTab == "Volume") ...[
            _buildCustomToggle("Recurring Alert", _recurringAlert, (v) => setState(() => _recurringAlert = v)),
            _buildCustomToggle("Send me a reminder 1 trading day before", _tradingReminder, (v) => setState(() => _tradingReminder = v)),
          ] else ...[
            _buildCustomToggle("Send an email notification", _emailNotification, (v) => setState(() => _emailNotification = v)),
          ],
          
          const SizedBox(height: 32),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildTabPicker() {
    return Row(
      children: ["Price", "Charge %", "Volume"].map((tab) {
        bool isSelected = _selectedTab == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = tab),
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

  Widget _buildInputArea() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintText: _selectedTab == "Charge %" ? "13%" : widget.lastPrice.toString(),
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
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? const Color(0xFF8B5CF6) : Colors.white24,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF4C3BB1), Color(0xFF3B2E8A)]),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Create", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}