import 'package:flutter/material.dart';

enum UserRole { ambassador, advertiser }

typedef OnRoleSelected = void Function(UserRole role);

class RoleSelector extends StatelessWidget {
  final OnRoleSelected onRoleSelected;
  const RoleSelector({Key? key, required this.onRoleSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => onRoleSelected(UserRole.ambassador),
          child: const Text('Ambassadeur'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => onRoleSelected(UserRole.advertiser),
          child: const Text('Annonceur'),
        ),
      ],
    );
  }
}
