import 'package:flutter/material.dart';

class NotificationDesignScreen extends StatefulWidget {
  const NotificationDesignScreen({Key? key}) : super(key: key);

  @override
  _NotificationDesignScreenState createState() =>
      _NotificationDesignScreenState();
}

class _NotificationDesignScreenState extends State<NotificationDesignScreen> {
  String _selectedOption = 'all';
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Send Notification'),
        backgroundColor: const Color(0xFFF5141E),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
            tooltip: 'Notification History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      Icons.edit_note_rounded, 'Notification Details'),
                  const SizedBox(height: 16),
                  _buildNotificationDetailsCard(),

                  const SizedBox(height: 24),

                  // Recipients Card
                  _buildSectionTitle(Icons.people_alt_rounded, 'Recipients'),
                  const SizedBox(height: 16),
                  _buildRecipientsCard(),

                  const SizedBox(height: 32),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5141E),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.send_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'SEND NOTIFICATION',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3F51B5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationDetailsCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Notification Title',
                labelStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Enter title here...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.title_rounded,
                  color: Colors.black87,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black45, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Message Input
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notification Message',
                labelStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'Enter message here...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 45),
                  child: Icon(
                    Icons.message_rounded,
                    color: Colors.black87,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Image Upload Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      color: Color(0xFF3F51B5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Image (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Upload',
                      style: TextStyle(color: Color(0xFF3F51B5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All Users Option
            InkWell(
              onTap: () {
                setState(() {
                  _selectedOption = 'all';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedOption == 'all'
                      ? const Color(0xFF3F51B5).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedOption == 'all'
                        ? const Color(0xFF3F51B5)
                        : Colors.grey[300]!,
                    width: _selectedOption == 'all' ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedOption == 'all'
                            ? const Color(0xFF3F51B5)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        color: _selectedOption == 'all'
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Users',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send to all registered users',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio(
                      value: 'all',
                      groupValue: _selectedOption,
                      activeColor: const Color(0xFF3F51B5),
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value as String;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Specific User Option
            InkWell(
              onTap: () {
                setState(() {
                  _selectedOption = 'specific';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedOption == 'specific'
                      ? const Color(0xFF3F51B5).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedOption == 'specific'
                        ? const Color(0xFF3F51B5)
                        : Colors.grey[300]!,
                    width: _selectedOption == 'specific' ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedOption == 'specific'
                            ? const Color(0xFF3F51B5)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: _selectedOption == 'specific'
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Specific User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send to a selected individual user',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio(
                      value: 'specific',
                      groupValue: _selectedOption,
                      activeColor: const Color(0xFF3F51B5),
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value as String;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // User Selection Dropdown (visible when "specific" is selected)
            if (_selectedOption == 'specific')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('Select User'),
                      isExpanded: true,
                      value: _selectedUserId,
                      items: [
                        DropdownMenuItem(
                          value: 'user1',
                          child: _buildUserItem('John Doe', 'john@example.com'),
                        ),
                        DropdownMenuItem(
                          value: 'user2',
                          child: _buildUserItem(
                              'Sarah Smith', 'sarah@example.com'),
                        ),
                        DropdownMenuItem(
                          value: 'user3',
                          child: _buildUserItem(
                              'Mike Johnson', 'mike@example.com'),
                        ),
                      ],
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserId = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(String name, String email) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF3F51B5).withOpacity(0.2),
          radius: 16,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF3F51B5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
