import 'package:flutter/material.dart';
import '../../screens/admin/admin_users_list_screen.dart';

// --- MOCK DATA FOR HIERARCHY ---
// Estrutura:
// Estados -> Cidades -> Igrejas

const Map<String, dynamic> mockLocationData = {
  'TO': {
    'name': 'Tocantins',
    'cities': {
      'Palmas': [
        {'id': 'metodista_palmas', 'name': 'Igreja Metodista de Palmas'},
        {'id': 'igreja_centro', 'name': 'Igreja do Centro'},
        {'id': 'igreja_sul', 'name': 'Igreja da Região Sul'},
      ],
      'Araguaína': [
        {'id': 'metodista_araguaina', 'name': 'Igreja Metodista Central'},
      ],
      'Gurupi': [], // Sem igrejas cadastradas
    }
  },
  'SP': {
    'name': 'São Paulo',
    'cities': {
      'São Paulo': [
        {'id': 'catedral_sp', 'name': 'Catedral Metodista de SP'},
      ],
      'Campinas': [],
    }
  },
  'RJ': {
    'name': 'Rio de Janeiro',
    'cities': {
      'Rio de Janeiro': [],
    }
  }
};

/// -----------------------------------------------------------
/// TELA NÍVEL 1: LISTA DE ESTADOS (States)
/// -----------------------------------------------------------
class SuperAdminStateListScreen extends StatelessWidget {
  const SuperAdminStateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final states = mockLocationData.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Selecione o Estado')),
      body: ListView.separated(
        itemCount: states.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final uf = states[index];
          final stateName = mockLocationData[uf]['name'];
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(uf, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(stateName),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SuperAdminCityListScreen(uf: uf),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// -----------------------------------------------------------
/// TELA NÍVEL 2: LISTA DE CIDADES (Cities)
/// -----------------------------------------------------------
class SuperAdminCityListScreen extends StatelessWidget {
  final String uf; // Estado selecionado (ex: "TO")

  const SuperAdminCityListScreen({super.key, required this.uf});

  @override
  Widget build(BuildContext context) {
    final stateData = mockLocationData[uf];
    final Map<String, dynamic> citiesMap = stateData['cities'];
    final cities = citiesMap.keys.toList();

    return Scaffold(
      appBar: AppBar(title: Text('Cidades - $uf')),
      body: cities.isEmpty 
        ? const Center(child: Text('Nenhuma cidade cadastrada neste estado.'))
        : ListView.separated(
          itemCount: cities.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final cityName = cities[index];
            final churches = citiesMap[cityName] as List;

            return ListTile(
              leading: const Icon(Icons.location_city, color: Colors.blueGrey),
              title: Text(cityName),
              subtitle: Text('${churches.length} igrejas cadastradas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuperAdminChurchListScreen(
                      uf: uf,
                      cityName: cityName,
                      churches: churches,
                    ),
                  ),
                );
              },
            );
          },
        ),
    );
  }
}

/// -----------------------------------------------------------
/// TELA NÍVEL 3: LISTA DE IGREJAS (Churches)
/// -----------------------------------------------------------
class SuperAdminChurchListScreen extends StatelessWidget {
  final String uf;
  final String cityName;
  final List<dynamic> churches;

  const SuperAdminChurchListScreen({
    super.key,
    required this.uf,
    required this.cityName,
    required this.churches,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Igrejas em $cityName')),
      body: churches.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.church_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Nenhuma igreja em $cityName'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                     // Futuro: Adicionar Igreja
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Funcionalidade "Criar Igreja" em breve.')),
                     );
                  }, 
                  child: const Text('Cadastrar Nova Igreja')
                )
              ],
            ),
          )
        : ListView.builder(
          itemCount: churches.length,
          itemBuilder: (context, index) {
            final church = churches[index];
            final churchId = church['id'];
            final churchName = church['name'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.church, color: Colors.indigo),
                title: Text(churchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: $churchId'),
                trailing: const Icon(Icons.people, color: Colors.green),
                onTap: () {
                  // NAVEGAÇÃO PARA A TELA FINAL (LISTA DE USUÁRIOS)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUsersListScreen(churchId: churchId),
                    ),
                  );
                },
              ),
            );
          },
        ),
    );
  }
}
