import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../models/pix_statement_item.dart';

class PixStatementTile extends StatelessWidget {
  const PixStatementTile({
    super.key,
    required this.item,
    required this.onOpenReceipt,
    required this.onCancel,
    required this.onShare,
  });

  final PixStatementItem item;
  final VoidCallback onOpenReceipt;
  final VoidCallback onCancel;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: ListTile(
        onTap: item.canOpenReceipt ? onOpenReceipt : null,
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.signedAmount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: item.amountColor,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title),
              const SizedBox(height: 4),
              Text(
                '${item.formattedDate} • ${item.statusLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: item.status == 'pendente'
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancelar Pix',
                onPressed: onCancel,
              )
            : item.canShare
                ? IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Compartilhar comprovante',
                    onPressed: onShare,
                  )
                : null,
      ),
    );
  }
}

class ActiveFiltersBanner extends StatelessWidget {
  const ActiveFiltersBanner({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          const Expanded(child: Text('Filtros aplicados')),
          TextButton(
            onPressed: onClear,
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class CenteredState extends StatelessWidget {
  const CenteredState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
