import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/filter_type.dart';
import '../../../../data/models/scanned_page_model.dart';

/// Modal interactivo para seleccionar y previsualizar filtros de mejora para una página
class PageFilterView extends StatefulWidget {
  final ScannedPageModel page;
  final ValueChanged<FilterType> onFilterSelected;

  const PageFilterView({
    super.key,
    required this.page,
    required this.onFilterSelected,
  });

  @override
  State<PageFilterView> createState() => _PageFilterViewState();
}

class _PageFilterViewState extends State<PageFilterView> {
  late FilterType _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.page.filter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: Text(
          'Filtro - Página ${widget.page.pageNumber}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.primaryLight),
            onPressed: () {
              widget.onFilterSelected(_selectedFilter);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Vista previa principal
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.page.processedImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Selector horizontal de filtros
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: const Color(0xFF1E1E1E),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.selectFilter,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: FilterType.values.map((filter) {
                      final isSelected = filter == _selectedFilter;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.grey.shade800,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                filter.icon,
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filter.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
