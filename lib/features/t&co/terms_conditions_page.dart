// import 'package:ecotrack_mobile/features/auth/register_page.dart';
// import 'package:flutter/material.dart';


// class TermsConditionsPage extends StatefulWidget {
//   const TermsConditionsPage({Key? key}) : super(key: key);

//   @override
//   State<TermsConditionsPage> createState() => _TermsConditionsPageState();
// }

// class _TermsConditionsPageState extends State<TermsConditionsPage> {
//   bool isChecked = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Terms & Agreement")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const Text("Welcome to EcoTrack App, BATELEC I",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             const Expanded(
//               child: SingleChildScrollView(
//                 child: Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean venenatis a velit quis tristique. Ut condimentum dapibus turpis in imperdiet. Duis sed malesuada turpis. Ut mattis nunc eu feugiat pharetra. Mauris faucibus dictum risus, vestibulum semper ligula tincidunt ac. Nunc ullamcorper, orci in molestie porta, magna ligula sagittis enim, consequat posuere libero nunc eget eros. Curabitur nulla ex, vestibulum in facilisis nec, faucibus id ipsum. Ut auctor tellus sem, eget fringilla massa malesuada et. Interdum et malesuada fames ac ante ipsum primis in faucibus. In erat elit, lobortis sed est eu, rhoncus commodo augue. Sed cursus faucibus erat a posuere. Nunc ut suscipit nibh. Nunc pulvinar risus ut pulvinar accumsan. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Nullam gravida vulputate diam sed tristique. Aliquam varius nisi ac pulvinar fringilla. Sed luctus dapibus urna quis egestas. Sed ex diam, blandit et metus et, ultricies ullamcorper eros. Ut est lectus, condimentum at pellentesque eu, elementum in metus. Nulla quis sapien quam. Integer vel arcu lectus. Aenean vestibulum est turpis, non dapibus lorem pellentesque vitae. Pellentesque faucibus diam at nibh dapibus, ac ullamcorper nibh consectetur. Nunc sed dignissim augue. Duis pulvinar lacus quis sem. Proin lorem leo, auctor quis elit et, posuere facilisis quam. Suspendisse ex purus, sodales nec turpis in, semper lacinia arcu. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean venenatis a velit quis tristique. Ut condimentum dapibus turpis in imperdiet. Duis sed malesuada turpis. Ut mattis nunc eu feugiat pharetra. Mauris faucibus dictum risus, vestibulum semper ligula tincidunt ac. Nunc ullamcorper, orci in molestie porta, magna ligula sagittis enim, consequat posuere libero nunc eget eros. Curabitur nulla ex, vestibulum in facilisis nec, faucibus id ipsum. Ut auctor tellus sem, eget fringilla massa malesuada et. Interdum et malesuada fames ac ante ipsum primis in faucibus. In erat elit, lobortis sed est eu, rhoncus commodo augue. Sed cursus faucibus erat a posuere. Nunc ut suscipit nibh. Nunc pulvinar risus ut pulvinar accumsan. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Nullam gravida vulputate diam sed tristique. Aliquam varius nisi ac pulvinar fringilla. Sed luctus dapibus urna quis egestas. Sed ex diam, blandit et metus et, ultricies ullamcorper eros. Ut est lectus, condimentum at pellentesque eu, elementum in metus. Nulla quis sapien quam. Integer vel arcu lectus. Aenean vestibulum est turpis, non dapibus lorem pellentesque vitae. Pellentesque faucibus diam at nibh dapibus, ac ullamcorper nibh consectetur. Nunc sed dignissim augue. Duis pulvinar lacus quis sem. Proin lorem leo, auctor quis elit et, posuere facilisis quam. Suspendisse ex purus, sodales nec turpis in, semper lacinia arcu. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean venenatis a velit quis tristique. Ut condimentum dapibus turpis in imperdiet. Duis sed malesuada turpis. Ut mattis nunc eu feugiat pharetra. Mauris faucibus dictum risus, vestibulum semper ligula tincidunt ac. Nunc ullamcorper, orci in molestie porta, magna ligula sagittis enim, consequat posuere libero nunc eget eros. Curabitur nulla ex, vestibulum in facilisis nec, faucibus id ipsum. Ut auctor tellus sem, eget fringilla massa malesuada et. Interdum et malesuada fames ac ante ipsum primis in faucibus. In erat elit, lobortis sed est eu, rhoncus commodo augue. Sed cursus faucibus erat a posuere. Nunc ut suscipit nibh. Nunc pulvinar risus ut pulvinar accumsan. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Nullam gravida vulputate diam sed tristique. Aliquam varius nisi ac pulvinar fringilla. Sed luctus dapibus urna quis egestas. Sed ex diam, blandit et metus et, ultricies ullamcorper eros. Ut est lectus, condimentum at pellentesque eu, elementum in metus. Nulla quis sapien quam. Integer vel arcu lectus. Aenean vestibulum est turpis, non dapibus lorem pellentesque vitae. Pellentesque faucibus diam at nibh dapibus, ac ullamcorper nibh consectetur. Nunc sed dignissim augue. Duis pulvinar lacus quis sem. Proin lorem leo, auctor quis elit et, posuere facilisis quam. Suspendisse ex purus, sodales nec turpis in, semper lacinia arcu."),
//               ),
//             ),
//             Row(
//               children: [
//                 Checkbox(
//                   value: isChecked,
//                   onChanged: (value) {
//                     setState(() {
//                       isChecked = value!;
//                     });
//                   },
//                 ),
//                 const Text("I have read the Terms and Conditions"),
//               ],
//             ),
//             ElevatedButton(
//               onPressed: isChecked
//                   ? () {
//                       Navigator.push(context,
//                         MaterialPageRoute(builder: (context) => const RegisterPage()));
//                     }
//                   : null,
//               child: const Text("I Agree to the Terms & Conditions"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
