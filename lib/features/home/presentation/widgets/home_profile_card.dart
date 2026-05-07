import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeProfileCard extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final List<String> bannerMessages;
  final PageController bannerController;
  final int currentIndex;
  final Function(int) onPageChanged;

  const HomeProfileCard({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.bannerMessages,
    required this.bannerController,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  State<HomeProfileCard> createState() => _HomeProfileCardState();
}

class _HomeProfileCardState extends State<HomeProfileCard> {
  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1654676066221-500d63a81951?q=80&w=1740&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Evening',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.userName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // ✅ UPDATE CIRCLE AVATAR
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      backgroundImage: widget.userAvatar.isNotEmpty
                          ? NetworkImage(widget.userAvatar)
                          : null,
                      child: widget.userAvatar.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                const Spacer(),

                // ... bagian slider tetap sama ...
                _buildGlassSlider(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk merapikan kode slider
  Widget _buildGlassSlider() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: widget.bannerController,
                  onPageChanged: widget.onPageChanged,
                  itemCount: widget.bannerMessages.length,
                  itemBuilder: (context, index) {
                    return _buildBannerItem(index);
                  },
                ),
              ),
              _buildDotsIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.announcement, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.bannerMessages[index],
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.bannerMessages.length,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
          width: widget.currentIndex == index ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.currentIndex == index ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
