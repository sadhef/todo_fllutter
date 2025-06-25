import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // FIXED: Debounced search to improve performance
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    // Use Future.delayed to debounce search calls
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text.trim() == query) {
        context.read<TodoProvider>().searchTodos(query);
      }
    });
  }

  void _onFocusChanged() {
    setState(() {
      _isExpanded = _focusNode.hasFocus;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<TodoProvider>().searchTodos('');
    _focusNode.unfocus();
    setState(() {
      _isSearching = false;
    });
  }

  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      context.read<TodoProvider>().searchTodos(value.trim());
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Main search bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isExpanded ? 60 : 50,
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onSubmitted: _onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText:
                        'Search todos by title, description, or priority...',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: _isExpanded ? 14 : 13,
                    ),
                    prefixIcon: AnimatedRotation(
                      turns: _isSearching ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.search,
                        color: _isExpanded
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                        size: _isExpanded ? 24 : 20,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Search results count
                              if (_isSearching && todoProvider.todos.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${todoProvider.todos.length}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              // Clear button
                              IconButton(
                                icon: const Icon(Icons.clear),
                                color: Colors.grey[600],
                                iconSize: 20,
                                onPressed: _clearSearch,
                                tooltip: 'Clear search',
                              ),
                            ],
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(_isExpanded ? 15 : 12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(_isExpanded ? 15 : 12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(_isExpanded ? 15 : 12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: _isExpanded
                        ? Colors.white
                        : Theme.of(context).colorScheme.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: _isExpanded ? 16 : 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: _isExpanded ? 16 : 14,
                    color: Colors.black87,
                  ),
                ),
              ),

              // FIXED: Search suggestions and quick filters
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          // Quick search suggestions
                          if (_isExpanded && _searchController.text.isEmpty)
                            _buildQuickSearchSuggestions(todoProvider),

                          // Search results summary
                          if (_isSearching && _searchController.text.isNotEmpty)
                            _buildSearchResultsSummary(todoProvider),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickSearchSuggestions(TodoProvider todoProvider) {
    final suggestions = [
      {'label': 'High Priority', 'query': 'high', 'icon': Icons.priority_high},
      {'label': 'Medium Priority', 'query': 'medium', 'icon': Icons.remove},
      {'label': 'Low Priority', 'query': 'low', 'icon': Icons.expand_more},
      {'label': 'With Voice Notes', 'query': '', 'icon': Icons.mic},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Search',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: suggestions.map((suggestion) {
              return InkWell(
                onTap: () {
                  if (suggestion['label'] == 'With Voice Notes') {
                    // Filter to show only todos with voice notes
                    context.read<TodoProvider>().searchTodos('voice');
                  } else {
                    _searchController.text = suggestion['query'] as String;
                    _onSearchSubmitted(suggestion['query'] as String);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightPink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.softPink,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        suggestion['icon'] as IconData,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestion['label'] as String,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSummary(TodoProvider todoProvider) {
    final totalResults = todoProvider.todos.length;
    final completedCount =
        todoProvider.todos.where((t) => t.isCompleted).length;
    final pendingCount = totalResults - completedCount;
    final withVoiceNotes =
        todoProvider.todos.where((t) => t.hasVoiceNote).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Search Results',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (totalResults == 0)
                Text(
                  'No matches found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                )
              else
                Text(
                  '$totalResults result${totalResults != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          if (totalResults > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (pendingCount > 0) ...[
                  _buildResultStat(
                    icon: Icons.radio_button_unchecked,
                    label: '$pendingCount pending',
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 12),
                ],
                if (completedCount > 0) ...[
                  _buildResultStat(
                    icon: Icons.check_circle,
                    label: '$completedCount completed',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                ],
                if (withVoiceNotes > 0) ...[
                  _buildResultStat(
                    icon: Icons.mic,
                    label: '$withVoiceNotes with voice',
                    color: AppTheme.primaryColor,
                  ),
                ],
              ],
            ),
          ],

          // No results suggestions
          if (totalResults == 0 && _searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Try searching for:',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Task titles or descriptions\n• Priority levels (high, medium, low)\n• "voice" for tasks with voice notes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultStat({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
