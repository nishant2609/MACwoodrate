import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../utils/order_storage.dart';
import 'result_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> orders = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // Date filter
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      List<Order> loadedOrders = [];

      if (authProvider.currentCompany != null) {
        final orderService = OrderService();
        loadedOrders = await orderService.getOrders(
            authProvider.currentCompany!.id);
      }

      if (loadedOrders.isEmpty) {
        loadedOrders = await OrderStorage.readOrders();
      }

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Order> get filteredOrders {
    return orders.where((order) {
      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          order.orderId
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          order.itemDescription
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      // Date filter
      bool matchesDate = true;
      if (_fromDate != null) {
        matchesDate = matchesDate &&
            order.date.isAfter(
                _fromDate!.subtract(const Duration(days: 1)));
      }
      if (_toDate != null) {
        matchesDate = matchesDate &&
            order.date
                .isBefore(_toDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              onSurface: Colors.brown[800]!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              onSurface: Colors.brown[800]!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _deleteOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: Text(
              'Are you sure you want to delete order ${order.orderId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await OrderStorage.deleteOrder(order.orderId);

        if (!mounted) return;
        final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentCompany != null) {
          final orderService = OrderService();
          await orderService.deleteOrder(
              order.orderId, authProvider.currentCompany!.id);
        }

        await _loadOrders();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
    final displayFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order History',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search orders...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Date Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectFromDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _fromDate != null
                                    ? Colors.brown
                                    : Colors.grey[400]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _fromDate != null
                                  ? Colors.brown[50]
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: _fromDate != null
                                      ? Colors.brown
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _fromDate != null
                                      ? displayFormat.format(_fromDate!)
                                      : 'From Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _fromDate != null
                                        ? Colors.brown[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Text('→',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 16)),

                      const SizedBox(width: 8),

                      Expanded(
                        child: GestureDetector(
                          onTap: _selectToDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _toDate != null
                                    ? Colors.brown
                                    : Colors.grey[400]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _toDate != null
                                  ? Colors.brown[50]
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: _toDate != null
                                      ? Colors.brown
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _toDate != null
                                      ? displayFormat.format(_toDate!)
                                      : 'To Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _toDate != null
                                        ? Colors.brown[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (_fromDate != null || _toDate != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearDateFilter,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border:
                              Border.all(color: Colors.red[300]!),
                            ),
                            child: Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Active filter indicator
                  if (_fromDate != null || _toDate != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.brown[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt,
                              size: 14, color: Colors.brown[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Showing ${filteredOrders.length} of ${orders.length} orders',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(
                      isSmallScreen ? 20 : 40),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        searchQuery.isNotEmpty ||
                            _fromDate != null ||
                            _toDate != null
                            ? Icons.search_off
                            : Icons.inbox,
                        size: isSmallScreen ? 48 : 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(
                          height: isSmallScreen ? 12 : 16),
                      Text(
                        searchQuery.isNotEmpty ||
                            _fromDate != null ||
                            _toDate != null
                            ? 'No orders found'
                            : 'No orders saved yet',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: isSmallScreen ? 6 : 8),
                      Text(
                        searchQuery.isNotEmpty ||
                            _fromDate != null ||
                            _toDate != null
                            ? 'Try different search or date range'
                            : 'Start by creating your first order',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadOrders,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: 8,
                  ),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      margin: EdgeInsets.only(
                          bottom: isSmallScreen ? 8 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _viewOrderDetails(order),
                        borderRadius:
                        BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(
                              isSmallScreen ? 12 : 16),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          order.orderId,
                                          style: TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .bold,
                                            fontSize:
                                            isSmallScreen
                                                ? 14
                                                : 16,
                                          ),
                                          overflow:
                                          TextOverflow
                                              .ellipsis,
                                        ),
                                        if (isSmallScreen) ...[
                                          const SizedBox(
                                              height: 4),
                                          Text(
                                            '₹${order.total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors
                                                  .green[800],
                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isSmallScreen) ...[
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        Colors.green[100],
                                        borderRadius:
                                        BorderRadius
                                            .circular(12),
                                      ),
                                      child: Text(
                                        '₹${order.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors
                                              .green[800],
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view':
                                          _viewOrderDetails(
                                              order);
                                          break;
                                        case 'delete':
                                          _deleteOrder(order);
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext
                                    context) =>
                                    [
                                      const PopupMenuItem<String>(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.visibility, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('View Details'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete, size: 20, color: Colors.red),
                                            const SizedBox(width: 8),
                                            const Text('Delete',
                                                style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(
                                  height:
                                  isSmallScreen ? 8 : 12),

                              Text(
                                order.itemDescription,
                                style: TextStyle(
                                  fontSize:
                                  isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                                maxLines:
                                isSmallScreen ? 1 : 2,
                                overflow:
                                TextOverflow.ellipsis,
                              ),

                              SizedBox(
                                  height:
                                  isSmallScreen ? 6 : 8),

                              // Info Row
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 14,
                                          color:
                                          Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(
                                            order.date),
                                        style: TextStyle(
                                          color:
                                          Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inventory,
                                          size: 14,
                                          color:
                                          Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${order.components.length} components',
                                        style: TextStyle(
                                          color:
                                          Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calculate,
                                          size: 14,
                                          color:
                                          Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${order.totalCft.toStringAsFixed(1)} CFT',
                                        style: TextStyle(
                                          color:
                                          Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}