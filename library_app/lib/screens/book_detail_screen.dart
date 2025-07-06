// lib/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/providers/loan_provider.dart';
import 'package:library_app/providers/user_provider.dart';
import 'package:library_app/models/loan.dart';
import 'package:library_app/providers/notification_provider.dart';
import 'package:library_app/models/app_notification.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> 
    with TickerProviderStateMixin {
  DateTime? _selectedBorrowDate;
  DateTime? _selectedReturnDate;
  Loan? _activeLoan;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _startAnimations();
    
    // Fetch active loan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveLoan();
    });
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveLoan() async {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    if (!context.mounted) return;
    _activeLoan = await loanProvider.getActiveLoanForBook(widget.book.id!);
    setState(() {});
  }

  Future<void> _selectBorrowDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B73FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBorrowDate) {
      setState(() {
        _selectedBorrowDate = picked;
      });
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _selectedBorrowDate ?? DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B73FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedReturnDate) {
      setState(() {
        _selectedReturnDate = picked;
      });
    }
  }

  Future<void> _borrowBook() async {
    if (_selectedBorrowDate == null) {
      _showCustomSnackBar('Pilih tanggal pinjam.', isError: true);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    final currentUserId = userProvider.userId;
    final currentUserName = userProvider.currentUser?.name;

    if (currentUserId == null || currentUserName == null) {
      _showCustomSnackBar('Anda harus login untuk meminjam buku.', isError: true);
      return;
    }

    try {
      await loanProvider.borrowBook(
        book: widget.book,
        userId: currentUserId,
        userName: currentUserName,
        borrowDate: _selectedBorrowDate!,
        bookProvider: bookProvider,
      );
      
      await _fetchActiveLoan();

      final notification = AppNotification(
        id: '',
        title: 'Buku Berhasil Dipinjam!',
        message: 'Anda telah berhasil meminjam buku "${widget.book.title}".',
        timestamp: DateTime.now(),
        type: 'book_borrowed',
        relatedItemId: widget.book.id,
        userId: currentUserId,
      );
      await notificationProvider.addNotification(notification);

      if (!context.mounted) return;
      _showCustomSnackBar('Buku "${widget.book.title}" berhasil dipinjam!', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      _showCustomSnackBar('Gagal meminjam buku: ${e.toString()}', isError: true);
    }
  }

  Future<void> _returnBook() async {
    if (_selectedReturnDate == null) {
      _showCustomSnackBar('Pilih tanggal dikembalikan.', isError: true);
      return;
    }
    if (_activeLoan == null) {
      _showCustomSnackBar('Buku ini tidak sedang Anda pinjam.', isError: true);
      return;
    }
    if (_selectedReturnDate!.isBefore(_activeLoan!.borrowDate)) {
      _showCustomSnackBar('Tanggal dikembalikan tidak bisa sebelum tanggal pinjam.', isError: true);
      return;
    }

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;

    try {
      await loanProvider.returnBook(
        loan: _activeLoan!,
        returnDate: _selectedReturnDate!,
        bookProvider: bookProvider,
      );
      
      setState(() {
        _activeLoan = null;
        _selectedBorrowDate = null;
        _selectedReturnDate = null;
      });

      if (currentUserId != null) {
        final notification = AppNotification(
          id: '',
          title: 'Buku Berhasil Dikembalikan!',
          message: 'Anda telah berhasil mengembalikan buku "${widget.book.title}".',
          timestamp: DateTime.now(),
          type: 'book_returned',
          relatedItemId: widget.book.id,
          userId: currentUserId,
        );
        await notificationProvider.addNotification(notification);
      }

      if (!context.mounted) return;
      _showCustomSnackBar('Buku "${widget.book.title}" berhasil dikembalikan!', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      _showCustomSnackBar('Gagal mengembalikan buku: ${e.toString()}', isError: true);
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final currentBook = bookProvider.books.firstWhere(
      (b) => b.id == widget.book.id,
      orElse: () => widget.book,
    );

    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.userId;
    final isAdmin = userProvider.currentUser?.role == 'admin';

    final bool isBorrowed = currentBook.isBorrowed;
    final bool isBorrowedByCurrentUser = isBorrowed && currentBook.borrowedByUserId == currentUserId;
    final bool isBorrowedByOtherUser = isBorrowed && currentBook.borrowedByUserId != currentUserId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background floating particles
            ...List.generate(12, (index) => _buildFloatingParticle(index)),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Back Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Title with Animation
                          Expanded(
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: const Icon(
                                            Icons.book_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Detail Buku',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content Area
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: _buildContent(currentBook, isBorrowed, isBorrowedByCurrentUser, isBorrowedByOtherUser, isAdmin),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Book currentBook, bool isBorrowed, bool isBorrowedByCurrentUser, bool isBorrowedByOtherUser, bool isAdmin) {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: currentBook.imageUrl.isNotEmpty
                      ? Image.network(
                          currentBook.imageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.3),
                                  Colors.grey.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.3),
                                Colors.blue.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.book,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Book Details Card
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentBook.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Oleh: ${currentBook.author}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kategori: ${currentBook.categoryId}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Deskripsi:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentBook.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBorrowed
                        ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                        : [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isBorrowed ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBorrowed ? Icons.error : Icons.check_circle,
                          color: isBorrowed ? Colors.red : Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Status Peminjaman',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isBorrowed ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isBorrowed) ...[
                      if (isBorrowedByCurrentUser)
                        Text(
                          'Buku ini sedang Anda pinjam.',
                          style: TextStyle(color: Colors.red[700], fontSize: 16),
                        ),
                      if (isBorrowedByOtherUser)
                        Text(
                          'Buku ini sedang dipinjam oleh pengguna lain.',
                          style: TextStyle(color: Colors.red[700], fontSize: 16),
                        ),
                      if (_activeLoan != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tanggal Pinjam: ${DateFormat('dd MMM yyyy, HH:mm').format(_activeLoan!.borrowDate)}',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ],
                              ),
                              if (_activeLoan!.returnDate != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.event_available, size: 16, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tanggal Dikembalikan: ${DateFormat('dd MMM yyyy, HH:mm').format(_activeLoan!.returnDate!)}',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ] else
                      Text(
                        'Buku ini tersedia untuk dipinjam.',
                        style: TextStyle(color: Colors.green[700], fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (!isAdmin)
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildActionSection(isBorrowed, isBorrowedByCurrentUser, isBorrowedByOtherUser),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(bool isBorrowed, bool isBorrowedByCurrentUser, bool isBorrowedByOtherUser) {
    if (!isBorrowed) {
      return _buildBorrowSection();
    } else if (isBorrowedByCurrentUser) {
      return _buildReturnSection();
    } else {
      return _buildUnavailableSection();
    }
  }

  Widget _buildBorrowSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tanggal Pinjam:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                _selectedBorrowDate == null
                    ? 'Pilih Tanggal'
                    : DateFormat('dd MMM yyyy, HH:mm').format(_selectedBorrowDate!),
                style: TextStyle(
                  color: _selectedBorrowDate == null ? Colors.grey : Colors.black87,
                ),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: const Color(0xFF6B73FF),
              ),
              onTap: () => _selectBorrowDate(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B73FF), Color(0xFF667eea)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B73FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _borrowBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.book_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  'Pinjam Buku',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tanggal Dikembalikan:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                _selectedReturnDate == null
                    ? 'Pilih Tanggal'
                    : DateFormat('dd MMM yyyy, HH:mm').format(_selectedReturnDate!),
                style: TextStyle(
                  color: _selectedReturnDate == null ? Colors.grey : Colors.black87,
                ),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: Colors.green[600],
              ),
              onTap: () => _selectReturnDate(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _returnBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.assignment_return,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  'Kembalikan Buku',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, color: Colors.grey, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Buku sedang dipinjam pengguna lain.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = index * 50;
    final top = (random % 600).toDouble();
    final left = (random % 300).toDouble();

    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Positioned(
          top: top + 10 * (_rotationAnimation.value),
          left: left + 10 * (_rotationAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value * 6.28,
            child: Opacity(
              opacity: 0.3,
              child: Icon(
                Icons.circle,
                size: 10 + (index % 5).toDouble(),
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
