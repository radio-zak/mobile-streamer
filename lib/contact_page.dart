import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie można otworzyć linku.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontakt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _ContactInfoTile(
            icon: Icons.phone,
            label: 'Telefon antenowy',
            value: '(+48 42) 63 13 888',
            onTap: () => _launchUrl(context, 'tel:+48426313888'),
          ),
          const SizedBox(height: 16),
          _ContactInfoTile(
            icon: Icons.email,
            label: 'E-mail',
            value: 'radio@zak.lodz.pl',
            onTap: () => _launchUrl(context, 'mailto:radio@zak.lodz.pl'),
          ),
          const SizedBox(height: 16),
          _ContactInfoTile(
            icon: Icons.message,
            label: 'Napisz przez Messenger',
            onTap: () => _launchUrl(context, 'http://m.me/studentradiozak'),
          ),
          const Divider(height: 48),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              'Telefony redakcyjne',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.tealAccent),
            ),
          ),
          _ContactInfoTile(
            icon: Icons.phone_in_talk,
            label: 'Redakcja',
            value: '(+48 42) 63 12 844',
            onTap: () => _launchUrl(context, 'tel:+48426312844'),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _ContactInfoTile({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.tealAccent, size: 32),
      title: Text(label, style: Theme.of(context).textTheme.titleLarge),
      subtitle: value != null
          ? Text(
              value!,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}
