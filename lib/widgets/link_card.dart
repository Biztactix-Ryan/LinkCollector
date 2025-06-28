import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/link_model.dart';

class LinkCard extends StatelessWidget {
  final LinkModel link;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : (link.isRead ? 1 : 3),
      color: isDark ? const Color(0xFF1E293B) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
          ? BorderSide(color: Colors.grey[800]!, width: 0.5)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (link.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    link.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.link,
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              if (link.imageUrl != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            link.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: link.isRead 
                                ? (isDark ? Colors.grey[500] : Colors.grey.shade600)
                                : (isDark ? Colors.white : null),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!link.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.url,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (link.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        link.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(link.savedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}