import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PersistentBottomBarScaffold extends StatefulWidget {
  /// pass the required items for the tabs and BottomNavigationBar
  final List<PersistentTabItem> items;

  const PersistentBottomBarScaffold({Key? key, required this.items})
      : super(key: key);

  @override
  _PersistentBottomBarScaffoldState createState() =>
      _PersistentBottomBarScaffoldState();
}

class _PersistentBottomBarScaffoldState
    extends State<PersistentBottomBarScaffold> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        /// Check if curent tab can be popped
        if (widget.items[_selectedTab].navigatorkey?.currentState?.canPop() ??
            false) {
          widget.items[_selectedTab].navigatorkey?.currentState?.pop();
          return false;
        } else {
          // if current tab can't be popped then use the root navigator
          return true;
        }
      },
      child: Scaffold(
        /// Using indexedStack to maintain the order of the tabs and the state of the
        /// previously opened tab
        body: IndexedStack(
          index: _selectedTab,
          children: widget.items
              .map((page) => Navigator(
                    /// Each tab is wrapped in a Navigator so that naigation in
                    /// one tab can be independent of the other tabs
                    key: page.navigatorkey,
                    onGenerateInitialRoutes: (navigator, initialRoute) {
                      return [
                        MaterialPageRoute(builder: (context) => page.tab)
                      ];
                    },
                  ))
              .toList(),
        ),

        /// Define the persistent bottom bar
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            /// Check if the tab that the user is pressing is currently selected
            if (index == _selectedTab) {
              /// if you want to pop the current tab to its root then use
              widget.items[index].navigatorkey?.currentState
                  ?.popUntil((route) => route.isFirst);

              /// if you want to pop the current tab to its last page
              /// then use
              // widget.items[index].navigatorkey?.currentState?.pop();
            } else {
              setState(() {
                _selectedTab = index;
              });
            }
          },
          items: widget.items
              .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon), label: item.title))
              .toList(),
        ),
      ),
    );
  }
}

/// Model class that holds the tab info for the [PersistentBottomBarScaffold]
class PersistentTabItem {
  final Widget tab;
  final GlobalKey<NavigatorState>? navigatorkey;
  final String title;
  final IconData icon;

  PersistentTabItem(
      {required this.tab,
      this.navigatorkey,
      required this.title,
      required this.icon});
}

class PinterestGrid extends StatefulWidget {
  const PinterestGrid({Key? key}) : super(key: key);

  @override
  State<PinterestGrid> createState() => _PinterestGridState();
}

class _PinterestGridState extends State<PinterestGrid> {
  final rnd = Random();
  late List<int> extents;
  int crossAxisCount = 2;

  @override
  void initState() {
    super.initState();
    extents = List<int>.generate(100, (int index) => rnd.nextInt(5) + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemBuilder: (context, index) {
            final height = extents[index] * 100;
            return ImageTile(
              index: index,
              height: height,
            );
          },
          itemCount: extents.length,
        ),
      ),
    );
  }
}

class ImageTile extends StatelessWidget {
  const ImageTile({
    Key? key,
    required this.index,
    required this.height,
  }) : super(key: key);

  final int index;
  final int height;

  Future<ui.Image> _getImage() {
    Completer<ui.Image> completer = Completer<ui.Image>();
    NetworkImage('https://source.unsplash.com/random/300x$height?sig=$index')
        .resolve(const ImageConfiguration())
        .addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), // Adjust the radius as needed
      ),
      child: FutureBuilder<ui.Image>(
        future: _getImage(),
        builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
          if (snapshot.hasData) {
            ui.Image? image = snapshot.data;
            return RawImage(
              image: image!,
              width: image.width.toDouble(),
              height: image.height.toDouble(),
              fit: BoxFit.cover,
            );
          } else {
            return const Text('Loading Image...');
          }
        },
      ),
    );
  }
}
