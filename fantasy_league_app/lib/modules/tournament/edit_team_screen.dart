import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/avatar_image.dart';

class EditTeamScreen extends StatefulWidget {
  final Map<String, dynamic> teamDetails;
  const EditTeamScreen({super.key, required this.teamDetails});

  @override
  _EditTeamScreenState createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _nameController = TextEditingController();
  File? _logoFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.teamDetails['name'] ?? '';
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1024);
      if (picked != null) {
        setState(() => _logoFile = File(picked.path));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isSubmitting = true);
    Timer? updateTimeoutTimer;
    try {
      // Set a 12-second timeout to prevent button spinner from hanging
      updateTimeoutTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Update timed out. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });

      final resp = await ApiProvider().updateTeam(
          widget.teamDetails['id'].toString(),
          name: name,
          logoFile: _logoFile, onSendProgress: (sent, total) {
        // optionally show progress
      });

      // Cancel timeout since we got a response
      updateTimeoutTimer.cancel();

      if (resp != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team updated'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
        return;
      }
    } catch (e) {
      updateTimeoutTimer?.cancel();
      if (kDebugMode) debugPrint('Error updating team: $e');
      String errorMsg = 'Failed to update team';
      if (e is TimeoutException) {
        errorMsg = 'Update timed out. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      updateTimeoutTimer?.cancel();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.teamDetails['logo_url'];
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Team')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickLogo,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                child: _logoFile != null
                    ? CircleAvatar(
                        radius: 46, backgroundImage: FileImage(_logoFile!))
                    : (logoUrl != null && logoUrl.toString().isNotEmpty
                        ? AvatarImage(
                            imageUrl: logoUrl,
                            isCircle: true,
                            sizeValue: 96,
                            radius: 48,
                            entityType: 'team',
                          )
                        : const Icon(Icons.group, size: 48)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _pickLogo, child: const Text('Change Logo')),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Team Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
