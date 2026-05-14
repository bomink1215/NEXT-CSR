import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── 행정구역 데이터 ─────────────────────────────────────────────
const Map<String, List<String>> kRegions = {
  '서울특별시': ['강남구','강동구','강북구','강서구','관악구','광진구','구로구','금천구','노원구','도봉구','동대문구','동작구','마포구','서대문구','서초구','성동구','성북구','송파구','양천구','영등포구','용산구','은평구','종로구','중구','중랑구'],
  '경기도': ['가평군','고양시','과천시','광명시','광주시','구리시','군포시','김포시','남양주시','동두천시','부천시','성남시','수원시','시흥시','안산시','안성시','안양시','양주시','양평군','여주시','연천군','오산시','용인시','의왕시','의정부시','이천시','파주시','평택시','포천시','하남시','화성시'],
};

const Map<String, List<String>> kSeoulDongs = {
  '강남구': ['개포동','논현동','대치동','도곡동','삼성동','세곡동','수서동','신사동','압구정동','역삼동','일원동','자곡동','청담동'],
  '강동구': ['강일동','고덕동','길동','둔촌동','명일동','상일동','성내동','암사동','천호동'],
  '강북구': ['번동','미아동','수유동','우이동'],
  '강서구': ['가양동','개화동','공항동','과해동','내발산동','등촌동','마곡동','방화동','오곡동','오쇠동','외발산동','화곡동'],
  '관악구': ['남현동','봉천동','신림동'],
  '광진구': ['광장동','구의동','군자동','능동','자양동','중곡동','화양동'],
  '구로구': ['가리봉동','고척동','구로동','궁동','신도림동','오류동','온수동','천왕동','항동'],
  '금천구': ['가산동','독산동','시흥동'],
  '노원구': ['공릉동','상계동','월계동','중계동','하계동'],
  '도봉구': ['도봉동','방학동','쌍문동','창동'],
  '동대문구': ['답십리동','용두동','장안동','전농동','청량리동','회기동','휘경동'],
  '동작구': ['노량진동','대방동','동작동','본동','사당동','상도동','신대방동'],
  '마포구': ['공덕동','대흥동','도화동','동교동','마포동','망원동','상암동','서교동','성산동','아현동','염리동','용강동','합정동','현석동'],
  '서대문구': ['남가좌동','냉천동','대신동','대현동','독립문동','북가좌동','북아현동','신촌동','연희동','영천동','창천동','충정로동','홍은동','홍제동'],
  '서초구': ['내곡동','반포동','방배동','서초동','신원동','양재동','우면동','원지동','잠원동'],
  '성동구': ['금호동','마장동','사근동','성수동','송정동','옥수동','응봉동','행당동'],
  '성북구': ['길음동','돈암동','동선동','보문동','삼선동','석관동','성북동','안암동','장위동','정릉동','종암동'],
  '송파구': ['가락동','거여동','마천동','문정동','방이동','삼전동','석촌동','송파동','신천동','오금동','장지동','풍납동'],
  '양천구': ['목동','신월동','신정동'],
  '영등포구': ['당산동','대림동','도림동','문래동','신길동','양평동','여의도동','영등포동'],
  '용산구': ['갈월동','남영동','도원동','동자동','문배동','보광동','서계동','서빙고동','이촌동','이태원동','청파동','한강로동','한남동','효창동','후암동'],
  '은평구': ['갈현동','구산동','녹번동','대조동','불광동','수색동','신사동','역촌동','응암동','진관동'],
  '종로구': ['가회동','계동','공평동','교남동','명륜동','부암동','사직동','삼청동','숭인동','안국동','연건동','이화동','익선동','인사동','종로','창성동','청운동','체부동','통의동','평창동','필운동','행촌동','혜화동','홍지동'],
  '중구': ['광희동','남대문로','다산동','묵정동','방산동','북창동','소공동','수표동','신당동','을지로','장충동','정동','충무로','태평로','필동','황학동','회현동'],
  '중랑구': ['망우동','면목동','묵동','상봉동','신내동','중화동'],
};

const Map<String, Map<String, List<String>>> kGyeonggiGuDongs = {
  '수원시': {
    '장안구': ['조원동','파장동','율전동','천천동','정자동','이목동','연무동','영화동','송죽동'],
    '권선구': ['권선동','금곡동','고색동','오목천동','탑동','호매실동','당수동','입북동','구운동','평동','서둔동','세류동'],
    '팔달구': ['지동','우만동','인계동','행궁동','매산동','화서동','북수동','남창동','영동','교동','팔달로'],
    '영통구': ['영통동','광교동','망포동','매탄동','원천동','이의동','하동'],
  },
  '성남시': {
    '수정구': ['수진동','신흥동','태평동','단대동','복정동','창곡동','시흥동','금토동'],
    '중원구': ['중원동','하대원동','금광동','은행동','상대원동','도촌동','갈현동'],
    '분당구': ['야탑동','이매동','서현동','수내동','정자동','분당동','판교동','대장동','삼평동','백현동','운중동'],
  },
  '고양시': {
    '덕양구': ['행신동','화정동','원신동','가좌동','강매동','능곡동','원당동','화전동','벽제동','고양동','관산동','덕이동','사리현동','성사동','신원동','오금동','지축동','효자동'],
    '일산동구': ['일산동','백석동','마두동','정발산동','풍동','장항동','대화동','식사동'],
    '일산서구': ['탄현동','주엽동','대화동','가좌동','덕이동'],
  },
  '용인시': {
    '처인구': ['포곡읍','모현읍','남사읍','이동읍','원삼면','백암면','양지면','유방동','김량장동','역북동','삼가동','해곡동'],
    '기흥구': ['기흥동','보라동','상갈동','하갈동','신갈동','영덕동','구갈동','마북동','동백동','중동','보정동','언남동','공세동'],
    '수지구': ['죽전동','구성동','수지동','신봉동','풍덕천동','동천동','상현동','성복동','광교동'],
  },
  '안산시': {
    '상록구': ['사동','본오동','반월동','성포동','월피동','부곡동','팔곡동','건건동','수암동','장상동','장하동'],
    '단원구': ['고잔동','중앙동','호수동','초지동','선부동','화정동','와동','원곡동','신길동','대부동','선감동'],
  },
  '안양시': {
    '만안구': ['안양동','박달동','석수동','양화동'],
    '동안구': ['평촌동','비산동','관양동','귀인동','호계동','부흥동','달안동','갈산동','임곡동'],
  },
};

const Map<String, List<String>> kGyeonggiDongs = {
  '가평군': ['가평읍','청평면','설악면','조종면','북면','상면'],
  '과천시': ['갈현동','문원동','별양동','부림동','중앙동','주암동'],
  '광명시': ['광명동','노온사동','소하동','옥길동','일직동','철산동','하안동','가학동'],
  '광주시': ['곤지암읍','남한산성면','도척면','퇴촌면','실촌읍','오포읍','초월읍','태전동','경안동','광남동','송정동'],
  '구리시': ['갈매동','교문동','동구동','수택동','인창동','아천동','토평동'],
  '군포시': ['당동','대야미동','둔대동','산본동','속달동','부곡동','군포동'],
  '김포시': ['감정동','걸포동','고촌읍','구래동','대곶면','마산동','사우동','양촌읍','운양동','장기동','통진읍','풍무동','하성면','월곶면'],
  '남양주시': ['가운동','금곡동','다산동','별내동','수동면','와부읍','오남읍','진건읍','진접읍','퇴계원읍','화도읍','호평동','평내동','양정동','지금동','도농동'],
  '동두천시': ['광암동','생연동','송내동','지행동','탑동동','상패동','걸산동'],
  '부천시': ['고강동','괴안동','내동','도당동','범박동','상동','소사동','심곡동','오정동','원종동','중동','역곡동','춘의동','신중동','옥길동'],
  '시흥시': ['거모동','과림동','군자동','능곡동','대야동','매화동','목감동','신천동','은행동','장곡동','정왕동','조남동','도창동'],
  '안성시': ['공도읍','금광면','대덕면','미양면','보개면','서운면','양성면','원곡면','일죽면','죽산면','삼죽면','고삼면'],
  '양주시': ['광적면','남면','백석읍','은현면','장흥면','고암동','덕계동','덕정동','마전동','삼숭동','유양동','회암동','회정동'],
  '양평군': ['강상면','강하면','개군면','단월면','서종면','양동면','양서면','양평읍','옥천면','용문면','지평면','청운면'],
  '여주시': ['가남읍','강천면','금사면','대신면','북내면','산북면','여주읍','점동면','흥천면'],
  '연천군': ['관인면','군남면','미산면','백학면','신서면','왕징면','전곡읍','중면','청산면'],
  '오산시': ['갈곶동','궐동','금암동','부산동','서랑동','수청동','양산동','원동','은계동','청학동','초평동','누읍동'],
  '의왕시': ['고천동','내손동','오전동','청계동','포일동','학의동'],
  '의정부시': ['가능동','고산동','금오동','낙양동','녹양동','민락동','산곡동','신곡동','용현동','자금동','장암동','호원동','의정부동','흥선동'],
  '이천시': ['가남읍','대월면','마장면','모가면','백사면','부발읍','설성면','신둔면','장호원읍','호법면','이천동','중리동'],
  '파주시': ['광탄면','군내면','교하동','금촌동','낙하면','문산읍','법원읍','야당동','운정동','적성면','조리읍','진동면','탄현면','파주읍','파평면','월롱면'],
  '평택시': ['고덕면','군문동','독곡동','비전동','세교동','소사동','안중읍','오성면','용이동','유천동','장당동','진위면','청북읍','팽성읍','포승읍'],
  '포천시': ['가산면','관인면','군내면','내촌면','선단동','소흘읍','영북면','영중면','이동면','일동면','창수면','포천동','화현면'],
  '하남시': ['감북동','감일동','교산동','망월동','미사동','신장동','풍산동','덕풍동','창우동'],
  '화성시': ['기배동','남양읍','동탄동','봉담읍','비봉면','팔탄면','향남읍','우정읍','장안면','양감면','정남면','매송면','송산면','새솔동'],
};

final List<String> kSidos = kRegions.keys.toList();

bool isGyeonggiGuCity(String si) => kGyeonggiGuDongs.containsKey(si);

// ── 공용 위치 선택 바텀시트 ──────────────────────────────────────
/// 바텀시트를 열어 시/구/동을 선택하고 결과 문자열을 반환합니다.
/// 취소하거나 그냥 닫으면 null을 반환합니다.
Future<String?> showLocationPicker(
  BuildContext context, {
  String currentLocation = '',
}) async {
  final parts = currentLocation.split(' ').where((p) => p.isNotEmpty).toList();

  int tempSidoIdx = 0;
  int tempSigunIdx = 0;
  int tempGuIdx = 0;
  int tempDongIdx = 0;

  if (parts.isNotEmpty) {
    final si = kSidos.indexOf(parts[0]);
    if (si >= 0) {
      tempSidoIdx = si;
      final sido = kSidos[si];
      final siguns = kRegions[sido]!;
      if (parts.length >= 2) {
        final sgi = siguns.indexOf(parts[1]);
        if (sgi >= 0) {
          tempSigunIdx = sgi;
          final sigun = siguns[sgi];
          if (sido == '경기도' && isGyeonggiGuCity(sigun)) {
            final gus = kGyeonggiGuDongs[sigun]!.keys.toList();
            if (parts.length >= 3) {
              final gi = gus.indexOf(parts[2]);
              if (gi >= 0) {
                tempGuIdx = gi;
                final dongs = kGyeonggiGuDongs[sigun]![gus[gi]]!;
                if (parts.length >= 4) {
                  final di = dongs.indexOf(parts[3]);
                  if (di >= 0) tempDongIdx = di;
                }
              }
            }
          } else {
            List<String> dongs = sido == '서울특별시'
                ? (kSeoulDongs[sigun] ?? [])
                : (kGyeonggiDongs[sigun] ?? []);
            if (parts.length >= 3) {
              final di = dongs.indexOf(parts[2]);
              if (di >= 0) tempDongIdx = di;
            }
          }
        }
      }
    }
  }

  final sidoCtrl = FixedExtentScrollController(initialItem: tempSidoIdx);
  final sigunCtrl = FixedExtentScrollController(initialItem: tempSigunIdx);
  final guCtrl = FixedExtentScrollController(initialItem: tempGuIdx);
  final dongCtrl = FixedExtentScrollController(initialItem: tempDongIdx);

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final sido = kSidos[tempSidoIdx];
          final siguns = kRegions[sido]!;
          final sigun = siguns[tempSigunIdx.clamp(0, siguns.length - 1)];
          final isGuCity = sido == '경기도' && isGyeonggiGuCity(sigun);

          List<String> gus = [];
          List<String> dongs = [];

          if (sido == '서울특별시') {
            dongs = kSeoulDongs[sigun] ?? [];
          } else if (isGuCity) {
            gus = kGyeonggiGuDongs[sigun]!.keys.toList();
            final gu = gus.isNotEmpty
                ? gus[tempGuIdx.clamp(0, gus.length - 1)]
                : '';
            dongs = gu.isNotEmpty ? (kGyeonggiGuDongs[sigun]![gu] ?? []) : [];
          } else {
            dongs = kGyeonggiDongs[sigun] ?? [];
          }

          final safeGuIdx =
              tempGuIdx.clamp(0, gus.isEmpty ? 0 : gus.length - 1);
          final safeDongIdx =
              tempDongIdx.clamp(0, dongs.isEmpty ? 0 : dongs.length - 1);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text('주소 선택',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        final sd = kSidos[tempSidoIdx];
                        final sg =
                            kRegions[sd]![tempSigunIdx.clamp(0, kRegions[sd]!.length - 1)];
                        final isGu = sd == '경기도' && isGyeonggiGuCity(sg);
                        String loc;
                        if (isGu) {
                          final guList =
                              kGyeonggiGuDongs[sg]!.keys.toList();
                          final gu = guList[safeGuIdx];
                          final dongList = kGyeonggiGuDongs[sg]![gu]!;
                          final dong = dongList.isNotEmpty
                              ? dongList[safeDongIdx]
                              : '';
                          loc = '$sd $sg $gu $dong';
                        } else {
                          final dongList = sd == '서울특별시'
                              ? (kSeoulDongs[sg] ?? [])
                              : (kGyeonggiDongs[sg] ?? []);
                          final dong = dongList.isNotEmpty
                              ? dongList[safeDongIdx]
                              : '';
                          loc = '$sd $sg $dong';
                        }
                        Navigator.pop(ctx, loc.trim());
                      },
                      child: const Text('확인',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    // 시/도
                    Expanded(
                      flex: isGuCity ? 3 : 4,
                      child: ListWheelScrollView.useDelegate(
                        controller: sidoCtrl,
                        itemExtent: 44,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) {
                          setSheet(() {
                            tempSidoIdx = i;
                            tempSigunIdx = 0;
                            tempGuIdx = 0;
                            tempDongIdx = 0;
                          });
                          sigunCtrl.jumpToItem(0);
                          guCtrl.jumpToItem(0);
                          dongCtrl.jumpToItem(0);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: kSidos.length,
                          builder: (_, i) => LocationWheelItem(
                            text: kSidos[i],
                            isSelected: i == tempSidoIdx,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppColors.divider),
                    // 구/시/군
                    Expanded(
                      flex: isGuCity ? 3 : 3,
                      child: ListWheelScrollView.useDelegate(
                        controller: sigunCtrl,
                        itemExtent: 44,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) {
                          setSheet(() {
                            tempSigunIdx = i;
                            tempGuIdx = 0;
                            tempDongIdx = 0;
                          });
                          guCtrl.jumpToItem(0);
                          dongCtrl.jumpToItem(0);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: siguns.length,
                          builder: (_, i) => LocationWheelItem(
                            text: siguns[i],
                            isSelected: i == tempSigunIdx,
                          ),
                        ),
                      ),
                    ),
                    // 구 (경기 구도시만)
                    if (isGuCity && gus.isNotEmpty) ...[
                      Container(width: 1, color: AppColors.divider),
                      Expanded(
                        flex: 3,
                        child: ListWheelScrollView.useDelegate(
                          controller: guCtrl,
                          itemExtent: 44,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            setSheet(() {
                              tempGuIdx = i;
                              tempDongIdx = 0;
                            });
                            dongCtrl.jumpToItem(0);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: gus.length,
                            builder: (_, i) => LocationWheelItem(
                              text: gus[i],
                              isSelected: i == safeGuIdx,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // 동
                    if (dongs.isNotEmpty) ...[
                      Container(width: 1, color: AppColors.divider),
                      Expanded(
                        flex: 3,
                        child: ListWheelScrollView.useDelegate(
                          controller: dongCtrl,
                          itemExtent: 44,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            setSheet(() => tempDongIdx = i);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: dongs.length,
                            builder: (_, i) => LocationWheelItem(
                              text: dongs[i],
                              isSelected: i == safeDongIdx,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      );
    },
  );
}

// ── 휠 아이템 위젯 ───────────────────────────────────────────────
class LocationWheelItem extends StatelessWidget {
  final String text;
  final bool isSelected;

  const LocationWheelItem({
    required this.text,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSelected ? 15 : 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── 위치 선택 버튼 위젯 (재사용용) ───────────────────────────────
class LocationPickerButton extends StatelessWidget {
  final String selectedLocation;
  final String hint;
  final VoidCallback onTap;

  const LocationPickerButton({
    required this.selectedLocation,
    required this.onTap,
    this.hint = '주소를 선택해주세요',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedLocation.isEmpty
                ? AppColors.divider
                : AppColors.primary.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: selectedLocation.isEmpty
                  ? AppColors.textHint
                  : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedLocation.isEmpty ? hint : selectedLocation,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedLocation.isEmpty
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
