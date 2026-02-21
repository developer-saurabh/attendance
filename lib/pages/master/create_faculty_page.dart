import 'package:attendance/widgets/pp_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_text_field.dart';


class CreateFacultyPage extends StatefulWidget {
  const CreateFacultyPage({super.key});

  @override
  State<CreateFacultyPage> createState() => _CreateFacultyPageState();
}

class _CreateFacultyPageState extends State<CreateFacultyPage> {
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _nameC = TextEditingController();
  bool _loading = false;
  String? _msg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Faculty')),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(controller: _nameC, label: 'Name'),
                  const SizedBox(height: 16),
                  AppTextField(controller: _emailC, label: 'Email'),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordC,
                    label: 'Password (for faculty)',
                    obscure: true,
                  ),
                  const SizedBox(height: 16),
                  if (_msg != null)
                    Text(
                      _msg!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  const SizedBox(height: 16),
                  _loading
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: 'Create',
                          onPressed: () async {
                            setState(() {
                              _loading = true;
                              _msg = null;
                            });
                            try {
                              // Create auth user
                              final cred = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                email: _emailC.text.trim(),
                                password: _passwordC.text,
                              );
                              final uid = cred.user!.uid;

                              // Create Firestore doc
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .set({
                                'name': _nameC.text.trim(),
                                'email': _emailC.text.trim(),
                                'role': 'faculty',
                              });

                              setState(() {
                                _msg =
                                    'Faculty created. Share email & password with them.';
                              });
                            } catch (e) {
                              setState(() {
                                _msg = 'Error: $e';
                              });
                            } finally {
                              setState(() {
                                _loading = false;
                              });
                            }
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
