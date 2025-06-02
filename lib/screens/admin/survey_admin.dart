import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/base_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SurveyAdminPage extends StatefulWidget {
  const SurveyAdminPage({Key? key}) : super(key: key);

  @override
  _SurveyAdminPageState createState() => _SurveyAdminPageState();
}

class _SurveyAdminPageState extends State<SurveyAdminPage> {
  final SupabaseService _supabaseService = SupabaseService(Supabase.instance.client);
  List<Map<String, dynamic>> _surveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> surveys = await _supabaseService.getSurveys();
      setState(() {
        _surveys = surveys;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anketleri yuklerken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Anket Yonetimi',
      showSaveButton: false,
      onSavePressed: _saveSurvey,
      content: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _surveys.isEmpty
                  ? _buildEmptySurveyState()
                  : ListView.builder(
                      itemCount: _surveys.length,
                      itemBuilder: (context, index) {
                        final survey = _surveys[index];
                        final Color surveyColor = survey['renk'] != null 
                            ? _getColorFromValue(survey['renk']) 
                            : Colors.purple;
                        
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: surveyColor.withOpacity(0.7), width: 2),
                          ),
                          child: ExpansionTile(
                            leading: Icon(_getIconFromValue(survey['ikon']), color: surveyColor),
                            title: Text(survey['soru']),
                            subtitle: Text('${survey['secenekler'].length} secenek'),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secenekler:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    ...List.generate(
                                      survey['secenekler'].length,
                                      (i) => Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text('${i + 1}. ${survey['secenekler'][i]}'),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    if (survey['minYas'] != null)
                                      Text('Minimum Yas: ${survey['minYas']}'),
                                    if (survey['ilFiltresi'] == true)
                                      Text('Il Filtresi: ${survey['belirliIl'] ?? 'Tum iller'}'),
                                    if (survey['okulFiltresi'] == true)
                                      Text('Okul Filtresi: ${survey['belirliOkul'] ?? 'Tum okullar'}'),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: Icon(Icons.edit),
                                          label: Text('Duzenle'),
                                          onPressed: () => _editSurvey(survey),
                                        ),
                                        SizedBox(width: 8),
                                        TextButton.icon(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          label: Text('Sil', style: TextStyle(color: Colors.red)),
                                          onPressed: () => _deleteSurvey(survey['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _addNewSurvey(),
              child: Icon(Icons.add),
              backgroundColor: Color(0xFF5181BE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySurveyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.poll_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Henuz Anket Bulunmuyor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Yeni anket eklemek icin + butonuna tiklayin',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewSurvey() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SurveyDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      
      try {
        await _supabaseService.addSurvey(result);
        await _loadSurveys();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket basariyla eklendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket eklenirken hata olustu: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editSurvey(Map<String, dynamic> survey) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SurveyDialog(survey: survey),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      
      try {
        await _supabaseService.updateSurvey(survey['id'], result);
        await _loadSurveys();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket basariyla guncellendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket guncellenirken hata olustu: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSurvey(String surveyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anketi Sil'),
        content: Text('Bu anketi silmek istediginizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await _supabaseService.deleteSurvey(surveyId);
        await _loadSurveys();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket basariyla silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket silinirken hata olustu: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSurvey() async {
    // Implement save functionality if needed
  }

  // Icon degerini IconData'ya donusturur
  IconData _getIconFromValue(dynamic iconValue) {
    Map<String, IconData> iconMap = {
      'poll': Icons.poll,
      'how_to_vote': Icons.how_to_vote,
      'location_city': Icons.location_city,
      'school': Icons.school,
      'computer': Icons.computer,
      'public': Icons.public,
    };
    
    if (iconValue is int) {
      return IconData(iconValue, fontFamily: 'MaterialIcons');
    } else if (iconValue is String && iconMap.containsKey(iconValue)) {
      return iconMap[iconValue]!;
    }
    
    return Icons.poll;
  }

  // Renk degerini Color'a donusturur
  Color _getColorFromValue(dynamic colorValue) {
    Map<String, Color> colorMap = {
      'green': Colors.green,
      'blue': Colors.blue,
      'brown': Colors.brown,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'red': Colors.red,
    };
    
    if (colorValue is int) {
      return Color(colorValue);
    } else if (colorValue is String && colorMap.containsKey(colorValue)) {
      return colorMap[colorValue]!;
    }
    
    return Colors.purple;
  }
}

class _SurveyDialog extends StatefulWidget {
  final Map<String, dynamic>? survey;

  const _SurveyDialog({this.survey});

  @override
  _SurveyDialogState createState() => _SurveyDialogState();
}

class _SurveyDialogState extends State<_SurveyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _minAgeController;
  late TextEditingController _cityController;
  late TextEditingController _schoolController;
  String _selectedIcon = 'poll';
  String _selectedColor = 'blue';
  bool _cityFilter = false;
  bool _schoolFilter = false;
  String? _selectedCity;
  String? _selectedSchool;

  // Turkiye'deki illerin listesi
  final List<String> cities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya',
    'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik',
    'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
    'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir',
    'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul',
    'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis',
    'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa',
    'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye',
    'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop', 'Sivas', 'Şırnak',
    'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak'
  ];
  
  final List<String> schools = [
    'Okumuyorum',
    'Altınbaş Üniversitesi',
    'Bahçeşehir Üniversitesi',
    'Beykent Üniversitesi',
    'Boğaziçi Üniversitesi',
    'Galatasaray Üniversitesi',
    'Işık Üniversitesi',
    'İstanbul Kültür Üniversitesi',
    'İstanbul Medipol Üniversitesi',
    'İstanbul Sabahattin Zaim Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'İstanbul Ticaret Üniversitesi',
    'İstanbul Üniversitesi',
    'Koç Üniversitesi',
    'Maltepe Üniversitesi',
    'Marmara Üniversitesi',
    'Özyeğin Üniversitesi',
    'Sabancı Üniversitesi',
    'Yıldız Teknik Üniversitesi',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    final survey = widget.survey;
    
    _questionController = TextEditingController(text: survey?['soru']);
    _optionControllers = List.generate(
      survey?['secenekler']?.length ?? 2,
      (i) => TextEditingController(
        text: survey?['secenekler']?[i],
      ),
    );
    _minAgeController = TextEditingController(
      text: survey?['minYas']?.toString(),
    );
    
    if (survey != null) {
      _selectedIcon = survey['ikon'] ?? 'poll';
      _selectedColor = survey['renk'] ?? 'blue';
      _cityFilter = survey['ilFiltresi'] ?? false;
      _schoolFilter = survey['okulFiltresi'] ?? false;
      _selectedCity = survey['belirliIl'];
      _selectedSchool = survey['belirliOkul'];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _minAgeController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.survey == null ? 'Yeni Anket' : 'Anketi Duzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(labelText: 'Soru'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Lutfen bir soru girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Secenekler:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...List.generate(
                _optionControllers.length,
                (i) => Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          labelText: '${i + 1}. Secenek',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Bu alan bos birakilamaz';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeOption(i),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text('Secenek Ekle'),
                onPressed: _addOption,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _minAgeController,
                decoration: InputDecoration(labelText: 'Minimum Yas'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _cityFilter,
                    onChanged: (value) {
                      setState(() {
                        _cityFilter = value ?? false;
                        if (!_cityFilter) {
                          _selectedCity = null;
                        }
                      });
                    },
                  ),
                  Text('Il Filtresi'),
                ],
              ),
              if (_cityFilter)
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(labelText: 'Il Secin'),
                  items: cities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                  },
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _schoolFilter,
                    onChanged: (value) {
                      setState(() {
                        _schoolFilter = value ?? false;
                        if (!_schoolFilter) {
                          _selectedSchool = null;
                        }
                      });
                    },
                  ),
                  Text('Okul Filtresi'),
                ],
              ),
              if (_schoolFilter)
                DropdownButtonFormField<String>(
                  value: _selectedSchool,
                  decoration: InputDecoration(labelText: 'Okul Secin'),
                  items: schools.map((String school) {
                    return DropdownMenuItem<String>(
                      value: school,
                      child: Text(
                        school,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSchool = newValue;
                    });
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return schools.map<Widget>((String school) {
                      return Row(
                        children: [
                          Icon(Icons.school, color: Color(0xFF5181BE), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              school,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                  isExpanded: true,
                ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                decoration: InputDecoration(labelText: 'Ikon'),
                items: [
                  DropdownMenuItem(value: 'poll', child: Text('Anket')),
                  DropdownMenuItem(value: 'how_to_vote', child: Text('Oy')),
                  DropdownMenuItem(value: 'location_city', child: Text('Sehir')),
                  DropdownMenuItem(value: 'school', child: Text('Okul')),
                  DropdownMenuItem(value: 'computer', child: Text('Bilgisayar')),
                  DropdownMenuItem(value: 'public', child: Text('Dunya')),
                ],
                onChanged: (value) {
                  setState(() => _selectedIcon = value!);
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: InputDecoration(labelText: 'Renk'),
                items: [
                  DropdownMenuItem(value: 'blue', child: Text('Mavi')),
                  DropdownMenuItem(value: 'green', child: Text('Yesil')),
                  DropdownMenuItem(value: 'red', child: Text('Kirmizi')),
                  DropdownMenuItem(value: 'purple', child: Text('Mor')),
                  DropdownMenuItem(value: 'orange', child: Text('Turuncu')),
                  DropdownMenuItem(value: 'brown', child: Text('Kahverengi')),
                ],
                onChanged: (value) {
                  setState(() => _selectedColor = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Iptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final surveyData = {
                'soru': _questionController.text,
                'secenekler': _optionControllers.map((c) => c.text).toList(),
                'oylar': List<int>.filled(_optionControllers.length, 0),
                'ikon': _selectedIcon,
                'renk': _selectedColor,
                'minYas': int.tryParse(_minAgeController.text),
                'ilFiltresi': _cityFilter,
                'belirliIl': _cityFilter ? _selectedCity : null,
                'okulFiltresi': _schoolFilter,
                'belirliOkul': _schoolFilter ? _selectedSchool : null,
              };
              Navigator.pop(context, surveyData);
            }
          },
          child: Text('Kaydet'),
        ),
      ],
    );
  }
} 