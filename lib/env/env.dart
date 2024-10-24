import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'GBOOKS_APIKEY', obfuscate: true)
  static final String gBooksApiKey = _Env.gBooksApiKey;
}
