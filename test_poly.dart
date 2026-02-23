
void main() {
  bool isPointInPolygon(double lat, double lng, List<List<double>> polygon) {
    bool c = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i][1] > lng) != (polygon[j][1] > lng)) &&
          (lat <
              (polygon[j][0] - polygon[i][0]) *
                      (lng - polygon[i][1]) /
                      (polygon[j][1] - polygon[i][1]) +
                  polygon[i][0])) {
        c = !c;
      }
    }
    return c;
  }

  double lat = -18.4350779;
  double lng = -70.2915409;

  final zone3500 = <List<double>>[
    [-18.442889, -70.282444],
    [-18.444583, -70.299083],
    [-18.426583, -70.296944],
    [-18.426361, -70.281167],
  ];

  print(isPointInPolygon(lat, lng, zone3500));
}

