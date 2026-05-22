import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../model/deal.dart';

class ActiveDealsDialog extends StatefulWidget {
  final List<Deal> deals;

  const ActiveDealsDialog({Key? key, required this.deals}) : super(key: key);

  /// Shows the dialog. Safe to call when [deals] is empty (no-op).
  static Future<void> show(BuildContext context, List<Deal> deals) {
    if (deals.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ActiveDealsDialog(deals: deals),
    );
  }

  @override
  State<ActiveDealsDialog> createState() => _ActiveDealsDialogState();
}

class _ActiveDealsDialogState extends State<ActiveDealsDialog> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = widget.deals;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.maxFinite,
          height: 480,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: deals.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: deals[i].cacheBustedImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.black38, size: 48),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  spacing: 8,
                  children: [
                    Text(
                      deals[_currentPage].title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(deals.length, (i) {
                            final isActive = i == _currentPage;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 8,
                              width: isActive ? 20 : 8,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.black87 : Colors.black26,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
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
