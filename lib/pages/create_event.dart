import 'package:flutter/material.dart';

class CreateEventPage extends StatefulWidget {
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  String content = '';
  int participants = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Event', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image upload area
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(Icons.image,
                            size: 70, color: Color(0xFF4A7AFF)),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: GestureDetector(
                          onTap: () {},
                          child:
                              Icon(Icons.close, color: Colors.black, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Content field
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Write your content..',
                    filled: true,
                    fillColor: Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter content'
                      : null,
                  onSaved: (value) => content = value ?? '',
                ),
                SizedBox(height: 24),
                // Number of Participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Number of Participants',
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, size: 24),
                          onPressed: () {
                            setState(() {
                              if (participants > 1) participants--;
                            });
                          },
                        ),
                        Container(
                          width: 40,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$participants',
                              style: TextStyle(fontSize: 18)),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 24),
                          onPressed: () {
                            setState(() {
                              participants++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 32),
                // Post button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // TODO: Save event to backend
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Event Created!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Post',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
