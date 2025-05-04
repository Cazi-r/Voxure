import 'package:flutter/material.dart';
import '../../services/survey_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyAdminPage extends StatefulWidget {
  @override
  _SurveyAdminPageState createState() => _SurveyAdminPageState();
}

class _SurveyAdminPageState extends State<SurveyAdminPage> {
  final SurveyService _surveyService = SurveyService();
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
      List<Map<String, dynamic>> surveys = await _surveyService.getSurveys();
      setState(() {
        _surveys = surveys;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anketleri yüklerken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anket Yönetimi'),
        backgroundColor: Colors.purple,
        actions: [
        ],
      ),
      body: _isLoading
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
                      child: ListTile(
                        leading: Icon(
                          _getIconFromValue(survey['ikon']),
                          color: surveyColor,
                          size: 30,
                        ),
                        title: Text(
                          survey['soru'] ?? 'Başlıksız Anket',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${(survey['secenekler'] ?? []).length} seçenek | ' +
                            _getSurveyFilters(survey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editSurvey(survey),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSurvey(survey['id']),
                            ),
                          ],
                        ),
                        onTap: () => _viewSurveyDetails(survey),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addNewSurvey,
        backgroundColor: Colors.purple,
      ),
    );
  }

  // Anket olmadığında gösterilecek boş durum widget'ı
  Widget _buildEmptySurveyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.poll_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Henüz Anket Bulunmuyor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Yeni bir anket eklemek için + butonuna tıklayın',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getSurveyFilters(Map<String, dynamic> survey) {
    List<String> filters = [];
    
    if (survey['minYas'] != null && survey['minYas'] > 0) {
      filters.add('Min Yaş: ${survey['minYas']}');
    }
    
    if (survey['ilFiltresi'] == true && survey['belirliIl'] != null) {
      filters.add('İl: ${survey['belirliIl']}');
    }
    
    if (survey['okulFiltresi'] == true && survey['belirliOkul'] != null) {
      filters.add('Okul: ${survey['belirliOkul']}');
    }
    
    return filters.isNotEmpty ? filters.join(' | ') : 'Filtre yok';
  }

  IconData _getIconFromValue(dynamic iconValue) {
    // Basit bir ikonlar maplemesi
    Map<String, IconData> iconMap = {
      'how_to_vote': Icons.how_to_vote,
      'location_city': Icons.location_city,
      'school': Icons.school,
      'computer': Icons.computer,
      'public': Icons.public,
    };
    
    if (iconValue is int) {
      // IconData zaten bir int değeri olarak saklanmış olabilir
      return IconData(iconValue, fontFamily: 'MaterialIcons');
    } else if (iconValue is String && iconMap.containsKey(iconValue)) {
      return iconMap[iconValue]!;
    }
    
    // Varsayılan ikon
    return Icons.poll;
  }

  Color _getColorFromValue(dynamic colorValue) {
    // Basit bir renkler maplemesi
    Map<String, Color> colorMap = {
      'green': Colors.green,
      'blue': Colors.blue,
      'brown': Colors.brown,
      'orange': Colors.orange,
      'purple': Colors.purple,
    };
    
    if (colorValue is int) {
      // Color zaten bir int değeri olarak saklanmış olabilir
      return Color(colorValue);
    } else if (colorValue is String && colorMap.containsKey(colorValue)) {
      return colorMap[colorValue]!;
    }
    
    // Varsayılan renk
    return Colors.blue;
  }

  void _addNewSurvey() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SurveyFormPage(
          onSave: (newSurvey) async {
            await _surveyService.addSurvey(newSurvey);
            _loadSurveys();
          },
        ),
      ),
    );
  }

  void _editSurvey(Map<String, dynamic> survey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SurveyFormPage(
          survey: survey,
          onSave: (updatedSurvey) async {
            String surveyId = survey['id'];
            await _surveyService.updateSurvey(surveyId, updatedSurvey);
            _loadSurveys();
          },
        ),
      ),
    );
  }

  Future<void> _deleteSurvey(String surveyId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anketi Sil'),
        content: Text('Bu anketi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Sil'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _surveyService.deleteSurvey(surveyId);
        _loadSurveys();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket başarıyla silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anket silinirken hata: $e')),
        );
      }
    }
  }

  void _viewSurveyDetails(Map<String, dynamic> survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(survey['soru'] ?? 'Anket Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${survey['id']}'),
            SizedBox(height: 8),
            Text('Seçenekler:'),
            ...(survey['secenekler'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value.toString();
              int votes = survey['oylar'] != null && survey['oylar'].length > index
                  ? survey['oylar'][index]
                  : 0;
              return Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text('$option - $votes oy'),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Kapat'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;
  final Function(Map<String, dynamic>) onSave;

  SurveyFormPage({this.survey, required this.onSave});

  @override
  _SurveyFormPageState createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController> _optionControllers = [];
  int _minAge = 0;
  bool _cityFilter = false;
  String? _specificCity;
  bool _schoolFilter = false;
  String? _specificSchool;
  String _selectedIcon = 'poll';
  String _selectedColor = 'blue';

  // Türkiye'deki illerin listesi
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
  
  // Okulların listesi
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
    
    // Düzenleme modunda mevcut anket verilerini doldur
    if (widget.survey != null) {
      _questionController.text = widget.survey!['soru'] ?? '';
      
      List<dynamic> options = widget.survey!['secenekler'] ?? [];
      _optionControllers = List.generate(
        options.length,
        (index) => TextEditingController(text: options[index].toString()),
      );
      
      _minAge = widget.survey!['minYas'] ?? 0;
      
      _cityFilter = widget.survey!['ilFiltresi'] == true;
      _specificCity = widget.survey!['belirliIl'];
      
      _schoolFilter = widget.survey!['okulFiltresi'] == true;
      _specificSchool = widget.survey!['belirliOkul'];
      
      // İkon ve renk seçimi
      if (widget.survey!['ikon'] != null) {
        _selectedIcon = _getIconName(widget.survey!['ikon']);
      }
      
      if (widget.survey!['renk'] != null) {
        _selectedColor = _getColorName(widget.survey!['renk']);
      }
    } else {
      // Yeni anket için varsayılan olarak 2 seçenek
      _optionControllers = List.generate(
        2,
        (index) => TextEditingController(),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey != null ? 'Anketi Düzenle' : 'Yeni Anket'),
        backgroundColor: Colors.purple,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Anket Sorusu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir soru girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              Text(
                'Seçenekler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              // Seçenekler listesi
              ..._buildOptionFields(),
              
              SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Seçenek Ekle'),
                onPressed: _addOption,
              ),
              
              SizedBox(height: 16),
              Text(
                'Filtreler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              // Yaş filtresi
              Row(
                children: [
                  Text('Minimum Yaş:'),
                  SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: _minAge.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _minAge.toString(),
                      onChanged: (value) {
                        setState(() {
                          _minAge = value.round();
                        });
                      },
                    ),
                  ),
                  Text(_minAge.toString()),
                ],
              ),
              
              // İl filtresi
              CheckboxListTile(
                title: Text('İl Filtresi'),
                value: _cityFilter,
                onChanged: (value) {
                  setState(() {
                    _cityFilter = value ?? false;
                  });
                },
              ),
              
              if (_cityFilter)
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: DropdownButtonFormField<String>(
                    value: _specificCity,
                    decoration: InputDecoration(
                      labelText: 'Belirli İl',
                      border: OutlineInputBorder(),
                    ),
                    items: cities.map((String city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _specificCity = newValue;
                      });
                    },
                    validator: (value) {
                      if (_cityFilter && (value == null || value.isEmpty)) {
                        return 'İl bilgisi gerekli';
                      }
                      return null;
                    },
                  ),
                ),
              
              // Okul filtresi
              CheckboxListTile(
                title: Text('Okul Filtresi'),
                value: _schoolFilter,
                onChanged: (value) {
                  setState(() {
                    _schoolFilter = value ?? false;
                  });
                },
              ),
              
              if (_schoolFilter)
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: DropdownButtonFormField<String>(
                    value: _specificSchool,
                    decoration: InputDecoration(
                      labelText: 'Belirli Okul',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: schools.map((String school) {
                      return DropdownMenuItem<String>(
                        value: school,
                        child: Text(school, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _specificSchool = newValue;
                      });
                    },
                    validator: (value) {
                      if (_schoolFilter && (value == null || value.isEmpty)) {
                        return 'Okul bilgisi gerekli';
                      }
                      return null;
                    },
                  ),
                ),
              
              SizedBox(height: 16),
              
              // İkon seçimi
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'İkon',
                  border: OutlineInputBorder(),
                ),
                value: _selectedIcon,
                items: [
                  DropdownMenuItem(value: 'poll', child: Row(
                    children: [Icon(Icons.poll), SizedBox(width: 8), Text('Anket')],
                  )),
                  DropdownMenuItem(value: 'how_to_vote', child: Row(
                    children: [Icon(Icons.how_to_vote), SizedBox(width: 8), Text('Oy')],
                  )),
                  DropdownMenuItem(value: 'location_city', child: Row(
                    children: [Icon(Icons.location_city), SizedBox(width: 8), Text('Şehir')],
                  )),
                  DropdownMenuItem(value: 'school', child: Row(
                    children: [Icon(Icons.school), SizedBox(width: 8), Text('Okul')],
                  )),
                  DropdownMenuItem(value: 'computer', child: Row(
                    children: [Icon(Icons.computer), SizedBox(width: 8), Text('Bilgisayar')],
                  )),
                  DropdownMenuItem(value: 'public', child: Row(
                    children: [Icon(Icons.public), SizedBox(width: 8), Text('İnternet')],
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedIcon = value!;
                  });
                },
              ),
              
              SizedBox(height: 16),
              
              // Renk seçimi
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Renk',
                  border: OutlineInputBorder(),
                ),
                value: _selectedColor,
                items: [
                  DropdownMenuItem(value: 'blue', child: Row(
                    children: [Container(width: 24, height: 24, color: Colors.blue), SizedBox(width: 8), Text('Mavi')],
                  )),
                  DropdownMenuItem(value: 'green', child: Row(
                    children: [Container(width: 24, height: 24, color: Colors.green), SizedBox(width: 8), Text('Yeşil')],
                  )),
                  DropdownMenuItem(value: 'red', child: Row(
                    children: [Container(width: 24, height: 24, color: Colors.red), SizedBox(width: 8), Text('Kırmızı')],
                  )),
                  DropdownMenuItem(value: 'orange', child: Row(
                    children: [Container(width: 24, height: 24, color: Colors.orange), SizedBox(width: 8), Text('Turuncu')],
                  )),
                  DropdownMenuItem(value: 'purple', child: Row(
                    children: [Container(width: 24, height: 24, color: Colors.purple), SizedBox(width: 8), Text('Mor')],
                  )),
                  DropdownMenuItem(value: 'brown', child: Row(
                    children: [Container(width: 24, height: 24, color: Colors.brown), SizedBox(width: 8), Text('Kahverengi')],
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedColor = value!;
                  });
                },
              ),
              
              SizedBox(height: 32),
              
              // Kaydet butonu - tam genişlikte
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSurvey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      widget.survey != null ? 'Güncelle' : 'Kaydet',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    return _optionControllers.asMap().entries.map((entry) {
      int index = entry.key;
      TextEditingController controller = entry.value;
      
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Seçenek ${index + 1}',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seçenek boş olamaz';
                  }
                  return null;
                },
              ),
            ),
            if (_optionControllers.length > 2)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeOption(index),
              ),
          ],
        ),
      );
    }).toList();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _saveSurvey() {
    if (_formKey.currentState!.validate()) {
      // Anket verilerini oluştur
      String question = _questionController.text;
      List<String> options = _optionControllers
          .map((controller) => controller.text)
          .toList();
      
      Map<String, dynamic> survey = {
        'soru': question,
        'secenekler': options,
        'oylar': List<int>.filled(options.length, 0),
        'kilitlendi': false,
        'ikon': _getIconData(_selectedIcon),
        'renk': _getColorData(_selectedColor),
        'minYas': _minAge,
        'ilFiltresi': _cityFilter,
        'belirliIl': _cityFilter ? _specificCity : null,
        'okulFiltresi': _schoolFilter,
        'belirliOkul': _schoolFilter ? _specificSchool : null,
      };
      
      // ID yalnızca yeni giriş için otomatik oluşturulacak, mevcut anket için korunacak
      
      widget.onSave(survey);
      Navigator.of(context).pop();
    }
  }

  dynamic _getIconData(String iconName) {
    // İkon isimlerini IconData'ya dönüştür
    switch (iconName) {
      case 'poll': return 'poll';
      case 'how_to_vote': return 'how_to_vote';
      case 'location_city': return 'location_city';
      case 'school': return 'school';
      case 'computer': return 'computer';
      case 'public': return 'public';
      default: return 'poll';
    }
  }

  dynamic _getColorData(String colorName) {
    // Renk isimlerini Color değerine dönüştür
    return colorName;
  }

  String _getIconName(dynamic iconData) {
    // IconData'yı isime çevir
    if (iconData is int) {
      // İkon değerini IconData kodu olarak ele al ve bilinen kodları kontrol et
      if (iconData == Icons.poll.codePoint) return 'poll';
      if (iconData == Icons.how_to_vote.codePoint) return 'how_to_vote';
      if (iconData == Icons.location_city.codePoint) return 'location_city';
      if (iconData == Icons.school.codePoint) return 'school';
      if (iconData == Icons.computer.codePoint) return 'computer';
      if (iconData == Icons.public.codePoint) return 'public';
      return 'poll';
    } else if (iconData is String) {
      return iconData;
    }
    return 'poll';
  }

  String _getColorName(dynamic colorData) {
    // Color değerini isime çevir
    if (colorData is int) {
      // Renk değerini kontrol et
      if (colorData == Colors.blue.value) return 'blue';
      if (colorData == Colors.green.value) return 'green';
      if (colorData == Colors.red.value) return 'red';
      if (colorData == Colors.orange.value) return 'orange';
      if (colorData == Colors.purple.value) return 'purple';
      if (colorData == Colors.brown.value) return 'brown';
      return 'blue';
    } else if (colorData is String) {
      return colorData;
    }
    return 'blue';
  }
} 