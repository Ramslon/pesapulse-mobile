import 'package:flutter/material.dart';

class NoFilterResultsWidget extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const NoFilterResultsWidget({super.key, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'No matching expenses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              'Try changing your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),

            if (onClearFilters != null) ...[
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.refresh),
                label: const Text("Clear Filters"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
