import 'dart:async';

import 'package:certipath_app/core/theme.dart';
import 'package:certipath_app/features/home/data/constants/banner_constant.dart';
import 'package:certipath_app/features/home/presentation/widgets/home_login_placeholder.dart';
import 'package:certipath_app/features/home/presentation/widgets/product_grid_section.dart';
import 'package:certipath_app/features/home/presentation/widgets/product_title_section.dart';
import 'package:certipath_app/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:certipath_app/features/home/presentation/widgets/home_profile_card.dart';

import '../../auth/application/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  late PageController _bannerController;
  late AnimationController _heroController;
  Timer? _bannerTimer;

  bool _isCollapsed = false;
  bool _showScrollToTop = false;
  int _currentBannerIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _scrollController = ScrollController();

    _setupScrollListener();
    _startBannerAutoScroll();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Logika untuk menampilkan nama aplikasi "Certipath" di AppBar
      if (_scrollController.offset > 180 && !_isCollapsed) {
        setState(() => _isCollapsed = true);
      } else if (_scrollController.offset <= 180 && _isCollapsed) {
        setState(() => _isCollapsed = false);
      }

      // Logika untuk menampilkan tombol Scroll To Top
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextIndex =
            (_currentBannerIndex + 1) % HomeConstants.bannerMessages.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scrollController.dispose();
    _bannerController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    ref.invalidate(productsProvider(1));

    await ref.read(productsProvider(1).future);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = ref.watch(authProvider).user;

    if (user == null) {
      return HomeLoginPlaceholder();
    }

    return Scaffold(
      backgroundColor: AppColors.ecru,
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              elevation: 0,
              centerTitle: true,
              backgroundColor: AppColors.primary,
              title: _isCollapsed
                  ? Text(
                      'Certipath',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: HomeProfileCard(
                  userName: user.name,
                  userAvatar: user.avatar,
                  bannerMessages: HomeConstants.bannerMessages,
                  bannerController: _bannerController,
                  currentIndex: _currentBannerIndex,
                  onPageChanged: (index) {
                    setState(() => _currentBannerIndex = index);
                  },
                ),
              ),
            ),

            const ProductTitleSection(),

            const ProductGridSection(),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),

      floatingActionButton: _showScrollToTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton(
                heroTag: "scroll_top",
                onPressed: () => _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
                backgroundColor: AppColors.primary,
                elevation: 4,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
