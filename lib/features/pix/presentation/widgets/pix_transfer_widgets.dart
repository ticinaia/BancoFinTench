import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/repositories/pix_repository.dart';

class PixResumoLinha extends StatelessWidget {
  const PixResumoLinha({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteRecipientsStrip extends StatelessWidget {
  const FavoriteRecipientsStrip({
    super.key,
    required this.favorites,
    required this.onSelected,
  });

  final List<PixFavoriteRecipient> favorites;
  final ValueChanged<PixFavoriteRecipient> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          return ActionChip(
            avatar: const Icon(Icons.star_rounded, size: 18),
            label: SizedBox(
              width: 118,
              child: Text(
                favorite.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onPressed: () => onSelected(favorite),
          );
        },
      ),
    );
  }
}

class RecipientPreview extends StatelessWidget {
  const RecipientPreview({
    super.key,
    required this.recipient,
    this.onSave,
  });

  final PixRecipient recipient;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            recipient.isVerified
                ? Icons.verified_user_outlined
                : Icons.info_outline_rounded,
            color:
                recipient.isVerified ? AppColors.secondary : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  recipient.bank,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  recipient.isFavorite
                      ? 'Contato frequente'
                      : recipient.isVerified
                          ? 'Destinatário verificado'
                          : 'Chave não verificada. Salve o contato para reutilizar com nome correto.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: recipient.isVerified
                            ? AppColors.textSecondary
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (onSave != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.star_border_rounded),
                      label: const Text('Salvar contato'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
