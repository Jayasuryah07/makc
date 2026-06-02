import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:makc/Controller/controller.dart';
import 'package:makc/Model/banner_model.dart';
import 'package:makc/Model/profile_model.dart';
import 'package:makc/Model/service_,odel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Utils/api_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Controller controller = Get.put(Controller());
  PageController pageController = PageController(viewportFraction: 0.85);
  RxInt currentPage = 0.obs;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller.getLoginToken().then((value) {
      // Fetch profile data first to get user name
      ApiHelper.apiHelper.fetchProfile(token: controller.isLoginToken.value).then((profile) {
        controller.profileData.value = ProfileModel.fromJson(profile["data"]);
      });
      
      ApiHelper.apiHelper.fetchServiceBanner(token: controller.isLoginToken.value).then((banner) {
        ApiHelper.apiHelper.fetchService(token: controller.isLoginToken.value).then((service) {
          List filterList = banner["data"];
          List serviceFilterList = service["data"];
          controller.bannerList.value = filterList.map((e) => BannerDataModel.fromJson(e)).toList();
          controller.imagePath.value = "${banner["image_url"][1]["image_url"]}";
          controller.noImagePath.value = "${banner["image_url"][0]["image_url"]}";
          controller.serviceList.value = serviceFilterList.map((e) => ServiceDataModel.fromJson(e)).toList();
          controller.serviceImagePath.value = "${service["image_url"][1]["image_url"]}";
          controller.serviceNOImagePath.value = "${service["image_url"][0]["image_url"]}";
        });
      });
    });
    startAutoSlide();
    
    // Add listener for page changes
    pageController.addListener(() {
      currentPage.value = pageController.page?.round() ?? 0;
    });
  }

  void startAutoSlide() {
    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (controller.bannerList.isNotEmpty && pageController.hasClients) {
        int nextPage = pageController.page!.round() + 1;
        if (nextPage >= controller.bannerList.length) {
          nextPage = 0;
        }
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> checkApp({required String packageName, required String url}) async {
    bool? isInstalled = await InstalledApps.isAppInstalled(packageName);
    if (isInstalled!) {
      InstalledApps.startApp(packageName);
    } else {
      if (!await launchUrl(Uri.parse(url))) {
        throw Exception('Could not launch ${Uri.parse(url)}');
      }
    }
  }

  String getPackageName(String url) {
    Uri uri = Uri.parse(url);
    return uri.queryParameters['id'] ?? '';
  }

  @override
  void dispose() {
    timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom Header with User Greeting
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff2D3290),
                      Color(0xff4B4FC9),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Greeting and Profile Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome Back!",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Obx(
                                () => Text(
                                  controller.profileData.value.name?.isNotEmpty == true 
                                      ? controller.profileData.value.name! 
                                      : "User",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Profile Icon Button - Navigates to Profile Page
                        InkWell(
                          onTap: () {
                            controller.bottomIndex.value = 2;
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Main Content
            SliverToBoxAdapter(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Section Title - Our Services
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff2D3290), Color(0xff4B4FC9)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Our Services",
                            style: TextStyle(
                              color: Color(0xff2D3290),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Service Grid - Redesigned without blue backgrounds
                    controller.serviceList.isNotEmpty
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: controller.serviceList.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              return _buildServiceCard(index);
                            },
                          )
                        : _buildShimmerGrid(),
                    
                    const SizedBox(height: 24),
                    
                    // Banner Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff2D3290), Color(0xff4B4FC9)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Offers & Updates",
                            style: TextStyle(
                              color: Color(0xff2D3290),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Banner Carousel
                    controller.bannerList.isNotEmpty
                        ? SizedBox(
                            height: screenWidth / 2.2,
                            child: Stack(
                              children: [
                                PageView.builder(
                                  controller: pageController,
                                  itemCount: controller.bannerList.length,
                                  onPageChanged: (index) {
                                    currentPage.value = index;
                                  },
                                  itemBuilder: (context, index) {
                                    return AnimatedBuilder(
                                      animation: pageController,
                                      builder: (context, child) {
                                        double value = 0.0;
                                        if (pageController.position.haveDimensions) {
                                          value = (pageController.page! - index).abs();
                                          value = (1 - (value * 0.2)).clamp(0.8, 1.0);
                                        }
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Image.network(
                                                "${controller.imagePath.value}${controller.bannerList[index].serviceSubBanner}",
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                // Page Indicator Dots
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      controller.bannerList.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: currentPage.value == index ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: currentPage.value == index
                                              ? const Color(0xff2D3290)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildShimmerBanner(),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Service Card Widget - Redesigned without blue background
  Widget _buildServiceCard(int index) {
    return InkWell(
      onTap: () {
        String package = getPackageName(controller.serviceList[index].serviceUrl!);
        checkApp(
          packageName: package,
          url: controller.serviceList[index].serviceUrl!,
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Service Icon with clean design
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff2D3290).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Image.network(
                "${controller.serviceImagePath.value}${controller.serviceList[index].serviceLogo}",
                width: Get.width / 9,
                height: Get.width / 9,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.build, color: const Color(0xff2D3290), size: 28);
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.serviceList[index].serviceName ?? "",
              style: const TextStyle(
                color: Color(0xff2D3290),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer Effect for Loading State
  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: Get.width / 8,
                height: Get.width / 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Shimmer Banner
  Widget _buildShimmerBanner() {
    return Container(
      height: Get.width / 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xff2D3290)),
      ),
    );
  }
}