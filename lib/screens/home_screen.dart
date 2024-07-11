import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:here_maps_sample/models/search_result_model.dart';
import 'package:here_maps_sample/screens/login_screen.dart';
import 'package:here_maps_sample/utils/general_functions.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:here_sdk/routing.dart' as here;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController originController = TextEditingController();
  final TextEditingController destController = TextEditingController();
  final TextEditingController searchController = TextEditingController();


  GeoCoordinates? startingGeo;
  GeoCoordinates? endingGeo;

  final box = GetStorage();
  MapImage? _photoMapImage;
  MapCamera? _mapCamera;
  late SearchEngine _searchEngine;
  late HereMapController _hereMapController;
  SearchOptions searchOptions = SearchOptions();
  Timer? _debounce;
  List<SearchResultModel> searchItems = [];
  bool isInitial = true;
  MapMarker? currentPosMarker;
  MapMarker? originMarker;
  MapMarker? destMarker;
  late here.RoutingEngine _routingEngine;
  final List<MapPolyline> _mapRoutes = [];

  @override
  void initState() {
    super.initState();

    // init search engine
    try {
      _searchEngine = SearchEngine();
      _routingEngine = here.RoutingEngine();
    } on InstantiationException {
      throw Exception("Initialization of SearchEngine failed.");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            HereMap(onMapCreated: _onMapCreated),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Where are we heading today?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                    const SizedBox(
                      height: 16,
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(100)
                      ),
                      child: TextField(
                        controller: originController,
                        readOnly: true,
                        onTap: () {
                          showSearchSheet(0);
                        },
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter origin point",
                            prefixIcon: Icon(Icons.my_location),
                            contentPadding: EdgeInsets.only(top: 15)
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(100)
                      ),
                      child: TextField(
                        controller: destController,
                        readOnly: true,
                        onTap: () {
                          showSearchSheet(1);
                        },
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter destination point",
                            prefixIcon: Icon(Icons.location_on_rounded),
                            contentPadding: EdgeInsets.only(top: 15)
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _mapRoutes.isNotEmpty ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: const StadiumBorder(),
                          ),
                          onPressed: (){
                            _hereMapController.mapScene.removeMapPolylines(_mapRoutes);
                            _hereMapController.mapScene.removeMapMarkers([originMarker!, destMarker!]);
                            destMarker = null;
                            originMarker = null;
                            startingGeo = null;
                            endingGeo = null;
                            originController.clear();
                            destController.clear();
                            _mapRoutes.clear();
                            navigateToInitial();
                            setState(() {});
                          },
                          child: const Text('Reset'),
                        ) : const SizedBox(),
                        const SizedBox(
                          width: 16,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const StadiumBorder(),
                          ),
                          onPressed: (){

                            if(startingGeo == null || endingGeo == null){
                              showSnackBar(context, "Select locations", false);
                            }

                            if(_mapRoutes.isNotEmpty){
                              _hereMapController.mapScene.removeMapPolylines(_mapRoutes);
                            }

                            var startWaypoint = here.Waypoint.withDefaults(startingGeo!);
                            var destinationWaypoint = here.Waypoint.withDefaults(endingGeo!);

                            List<here.Waypoint> waypoints = [startWaypoint, destinationWaypoint];

                            _routingEngine.calculateCarRoute(waypoints, here.CarOptions(),
                                    (here.RoutingError? routingError, List<here.Route>? routeList) async {
                                  if (routingError == null) {
                                    // When error is null, it is guaranteed that the list is not empty.
                                    here.Route route = routeList!.first;
                                    MapPolyline routeMapPolyline = MapPolyline.withRepresentation(
                                      route.geometry,
                                      mapRouteRepresentation(),
                                    );
                                    routeMapPolyline.drawOrder = 1;
                                    _hereMapController.mapScene.addMapPolyline(routeMapPolyline);
                                    _mapRoutes.add(routeMapPolyline);
                                    setState(() {});
                                  } else {
                                    var error = routingError.toString();
                                    _showDialog('Error', 'Error while calculating a route: $error');
                                  }
                                });
                          },
                          child: const Text('Search'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  box.remove("login");
                  Navigator.of(context)
                      .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100)
                  ),
                  child: const Icon(Icons.power_settings_new, color: Colors.red, size: 32,),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    _hereMapController = hereMapController;
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (MapError? error) async {
      if (error != null) {
        debugPrint('Map scene not loaded. MapError: ${error.toString()}');
        return;
      }


      _mapCamera = hereMapController.camera;

      navigateToInitial();
    });
  }

  Future<Uint8List> _loadFileAsUint8List(String assetPathToFile) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load(assetPathToFile);
    return Uint8List.view(fileData.buffer);
  }


  searchQuery(TextQuery query, VoidCallback onFinish) {
    searchItems.clear();
    _searchEngine.searchByText(query, searchOptions, (SearchError? searchError, List<Place>? list) async {

      if (searchError != null) {
        // _showDialog("Search", "Error: $searchError");
        log(query.query);
        log(searchError.toString());
        return;
      }

      log((list?.length ?? 0).toString());

      // Add new marker for each search result on map.
      if(list == null) return;
      for (Place searchResult in list) {
        searchItems.add(SearchResultModel(searchResult.address.addressText, searchResult.geoCoordinates!));
      }

      onFinish();
    });
  }

  addMapMarker(String image, int type, GeoCoordinates geo) async {
    Uint8List imagePixelData = await _loadFileAsUint8List(image);
    var photoMapImageTmp = MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    const double distanceToEarthInMeters = 8000;
    MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);


    if(type == 0){
      if(originMarker != null){
        _hereMapController.mapScene.removeMapMarker(originMarker!);
      }
      originMarker = MapMarker(geo, photoMapImageTmp);
      _hereMapController.mapScene.addMapMarker(originMarker!);
      _hereMapController.camera.lookAtPointWithMeasure(geo, mapMeasureZoom);
    }else{
      if(destMarker != null){
        _hereMapController.mapScene.removeMapMarker(destMarker!);
      }
      destMarker = MapMarker(geo, photoMapImageTmp);
      _hereMapController.mapScene.addMapMarker(destMarker!);
      _hereMapController.camera.lookAtPointWithMeasure(geo, mapMeasureZoom);

    }

  }


  MapPolylineRepresentation mapRouteRepresentation() {
    return MapPolylineSolidRepresentation.withOutline(
      MapMeasureDependentRenderSize.withSingleSize(RenderSizeUnit.pixels, 16),
      const Color(0xFF8BE3A2),
      MapMeasureDependentRenderSize.withSingleSize(RenderSizeUnit.pixels, 12),
      const Color(0xFF6C8F61),
      LineCap.round,
    );
  }


  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSearchSheet(int type) {
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )
        ),
        builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(builder: (context, sheetState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(100)
                    ),
                    padding: const EdgeInsets.only(left: 16),
                    child: TextField(
                      controller: searchController,
                      onChanged: (val) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () async {
                          var query = TextQuery.withArea(searchController.text, TextQueryArea.withCenter(_mapCamera!.state.targetCoordinates));
                          searchQuery(query, () {
                            setState(() {});
                            sheetState(() {});
                          });
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter location here",
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                        itemCount: searchItems.length,
                        itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.location_on_rounded),
                        title: Text(searchItems[index].name),
                        onTap: () {
                          debugPrint(searchItems[index].geoCoordinates.latitude.toString());
                          debugPrint(searchItems[index].geoCoordinates.longitude.toString());
                          if(type == 0) {
                            originController.text = searchItems[index].name;
                            startingGeo = searchItems[index].geoCoordinates;
                            if(isInitial){
                              _hereMapController.mapScene.removeMapMarker(currentPosMarker!);
                            }
                            searchItems.clear();
                            searchController.clear();
                            isInitial = false;
                            Navigator.pop(context);
                            addMapMarker('assets/images/location.png', 0, startingGeo!);
                          }else {
                            destController.text = searchItems[index].name;
                            endingGeo = searchItems[index].geoCoordinates;
                            if(isInitial){
                              _hereMapController.mapScene.removeMapMarker(currentPosMarker!);
                            }
                            searchItems.clear();
                            searchController.clear();
                            isInitial = false;
                            Navigator.pop(context);
                            addMapMarker('assets/images/location-pin.png', 1, endingGeo!);
                          }
                        },
                      );
                    }),
                  )
                ],
              ),
            );
          }),
        ),
      );
    });
  }

  Future<void> navigateToInitial() async {
    const double distanceToEarthInMeters = 8000;
    MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);
    _hereMapController.camera.lookAtPointWithMeasure(GeoCoordinates(30.713130099022, 76.70761688465703), mapMeasureZoom);

    if (_photoMapImage == null) {
      Uint8List imagePixelData = await _loadFileAsUint8List('assets/images/pin-map.png');
      _photoMapImage = MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    }

    currentPosMarker = MapMarker(GeoCoordinates(30.713130099022, 76.70761688465703), _photoMapImage!);
    _hereMapController.mapScene.addMapMarker(currentPosMarker!);
  }
}
