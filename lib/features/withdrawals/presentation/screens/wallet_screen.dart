import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/features/withdrawals/presentation/screens/withdrawal_request_screen.dart';
import 'package:root2route/features/withdrawals/presentation/screens/withdrawal_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _balance = 0.0;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _fetchBalance();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService().getMyOrganizations();

      if (!mounted) return;

      if (result['success'] == true) {
        final List dataList = result['data'] ?? [];
        if (dataList.isNotEmpty && dataList[0] is Map) {
          final org = dataList[0] as Map;
          final rawBalance =
              org['walletBalance'] ?? org['WalletBalance'] ?? 0;
          _balance = double.tryParse(rawBalance.toString()) ?? 0.0;
        }
      } else {
        _error = result['message'] ?? 'فشل في تحميل الرصيد';
      }
    } catch (e) {
      if (!mounted) return;
      _error = 'حدث خطأ أثناء تحميل الرصيد';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'المحفظة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchBalance,
          color: AppColors.primary,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            children: [
              // ── Balance Card ─────────────────────────────────────
              _buildBalanceCard(isDark),
              SizedBox(height: 28.h),

              // ── Section Title ────────────────────────────────────
              Text(
                'العمليات',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              // ── Action Tiles ─────────────────────────────────────
              _buildActionTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'طلب سحب رصيد',
                subtitle: 'إنشاء طلب سحب رصيد جديد',
                iconBgColor: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WithdrawalRequestScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              _buildActionTile(
                icon: Icons.history_rounded,
                title: 'سجل طلبات السحب',
                subtitle: 'عرض جميع عمليات السحب السابقة',
                iconBgColor: Colors.orange.withValues(alpha: 0.12),
                iconColor: Colors.orange.shade700,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WithdrawalHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Balance Card ───────────────────────────────────────────────────
  Widget _buildBalanceCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B7A35), Color(0xFF2ECC71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative circles
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 24.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'الرصيد المتاح للسحب',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  )
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: _fetchBalance,
                          child: Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _balance.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            'EGP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Tile ────────────────────────────────────────────────────
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: iconColor, size: 26.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.w,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
