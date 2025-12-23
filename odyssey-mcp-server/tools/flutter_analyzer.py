"""
Flutter/Dart Code Analyzer
Analisa arquivos Dart em busca de padrões, issues e sugestões
"""

import re
from pathlib import Path
from typing import Any


class FlutterAnalyzer:
    """Analisador de código Flutter/Dart"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.lib_path = project_root / "lib"
    
    def analyze_file(self, file_path: str) -> dict[str, Any]:
        """Analisa um arquivo Dart específico"""
        full_path = self.project_root / file_path
        
        if not full_path.exists():
            return {"error": f"File not found: {file_path}"}
        
        try:
            content = full_path.read_text(encoding='utf-8')
            
            return {
                "file": file_path,
                "lines": len(content.splitlines()),
                "imports": self._extract_imports(content),
                "widgets": self._extract_widgets(content),
                "providers_used": self._extract_providers(content),
                "state_management": self._detect_state_management(content),
                "firebase_usage": self._detect_firebase_usage(content),
                "database_usage": self._detect_database_usage(content),
                "routing": self._detect_routing(content),
                "suggestions": self._generate_suggestions(content, file_path)
            }
        except Exception as e:
            return {"error": str(e)}
    
    def _extract_imports(self, content: str) -> list[str]:
        """Extrai imports do arquivo"""
        import_pattern = r"import\s+['\"](.+?)['\"]"
        return re.findall(import_pattern, content)
    
    def _extract_widgets(self, content: str) -> list[str]:
        """Extrai nomes de widgets definidos"""
        # Procura por classes que extends ou implements Widget-related
        widget_pattern = r"class\s+(\w+)\s+extends\s+(?:StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget|HookWidget)"
        return re.findall(widget_pattern, content)
    
    def _extract_providers(self, content: str) -> list[str]:
        """Extrai providers Riverpod usados"""
        # Procura por ref.watch() e ref.read()
        watch_pattern = r"ref\.watch\((\w+)\)"
        read_pattern = r"ref\.read\((\w+)\)"
        
        watches = re.findall(watch_pattern, content)
        reads = re.findall(read_pattern, content)
        
        return list(set(watches + reads))
    
    def _detect_state_management(self, content: str) -> str:
        """Detecta tipo de state management usado"""
        if "ConsumerWidget" in content or "ref.watch" in content:
            return "riverpod"
        elif "Provider.of" in content:
            return "provider"
        elif "BlocBuilder" in content or "BlocConsumer" in content:
            return "bloc"
        elif "GetX" in content or "Obx" in content:
            return "getx"
        else:
            return "none_detected"
    
    def _detect_firebase_usage(self, content: str) -> list[str]:
        """Detecta uso de Firebase"""
        firebase_services = []
        
        if "FirebaseFirestore" in content or "cloud_firestore" in content:
            firebase_services.append("firestore")
        if "FirebaseAuth" in content or "firebase_auth" in content:
            firebase_services.append("auth")
        if "FirebaseStorage" in content or "firebase_storage" in content:
            firebase_services.append("storage")
        if "FirebaseMessaging" in content or "firebase_messaging" in content:
            firebase_services.append("messaging")
        if "FirebaseAnalytics" in content:
            firebase_services.append("analytics")
            
        return firebase_services
    
    def _detect_database_usage(self, content: str) -> list[str]:
        """Detecta uso de databases"""
        databases = []
        
        if "Hive" in content or "@HiveType" in content:
            databases.append("hive")
        if "Isar" in content or "@collection" in content:
            databases.append("isar")
        if "sqflite" in content:
            databases.append("sqflite")
        if "SharedPreferences" in content:
            databases.append("shared_preferences")
            
        return databases
    
    def _detect_routing(self, content: str) -> dict[str, Any]:
        """Detecta configuração de rotas"""
        routing_info = {
            "type": "none",
            "routes": []
        }
        
        if "GoRoute" in content:
            routing_info["type"] = "go_router"
            # Extrai rotas GoRouter
            route_pattern = r"GoRoute\s*\([^)]*path:\s*['\"]([^'\"]+)['\"]"
            routing_info["routes"] = re.findall(route_pattern, content)
        elif "Navigator.pushNamed" in content:
            routing_info["type"] = "named_routes"
            
        return routing_info
    
    def _generate_suggestions(self, content: str, file_path: str) -> list[str]:
        """Gera sugestões de melhoria"""
        suggestions = []
        
        # Verifica uso de const
        if "Widget build" in content and content.count("const ") < 5:
            suggestions.append("Consider using 'const' constructors for better performance")
        
        # Verifica setState desnecessário
        if "setState" in content and "StatefulWidget" not in content:
            suggestions.append("setState found but not extending StatefulWidget")
        
        # Verifica imports não usados (simples)
        imports = self._extract_imports(content)
        for imp in imports:
            package_name = imp.split('/')[0] if '/' in imp else imp
            if package_name not in content.replace(imp, ''):
                suggestions.append(f"Import '{imp}' may be unused")
        
        # Verifica performance
        if "ListView(" in content and "ListView.builder" not in content:
            suggestions.append("Consider using ListView.builder for better performance with large lists")
        
        # Verifica context usage
        if "BuildContext" in content and "mounted" not in content and "async" in content:
            suggestions.append("Consider checking 'mounted' before using context after async operations")
        
        return suggestions
    
    def analyze_performance(self, file_path: str) -> dict[str, Any]:
        """Analisa performance de um arquivo"""
        full_path = self.project_root / file_path
        
        if not full_path.exists():
            return {"error": f"File not found: {file_path}"}
        
        content = full_path.read_text(encoding='utf-8')
        
        issues = []
        
        # Rebuild issues
        if "setState" in content:
            setstate_count = content.count("setState")
            if setstate_count > 5:
                issues.append({
                    "type": "performance",
                    "severity": "medium",
                    "message": f"Multiple setState calls ({setstate_count}) - consider state management"
                })
        
        # Widget rebuilds
        if "build(" in content and "const " not in content:
            issues.append({
                "type": "performance",
                "severity": "low",
                "message": "Consider using const widgets to prevent unnecessary rebuilds"
            })
        
        # List performance
        if re.search(r"ListView\s*\(", content):
            issues.append({
                "type": "performance",
                "severity": "medium",
                "message": "Use ListView.builder instead of ListView for better performance"
            })
        
        # Heavy operations in build
        if "build(" in content and any(op in content for op in ["File(", "http.get", "Future.delayed"]):
            issues.append({
                "type": "performance",
                "severity": "high",
                "message": "Avoid heavy operations directly in build method"
            })
        
        return {
            "file": file_path,
            "issues": issues,
            "score": max(0, 100 - len(issues) * 10)
        }
    
    def check_firebase_integration(self) -> dict[str, Any]:
        """Verifica integração Firebase"""
        pubspec = self.project_root / "pubspec.yaml"
        
        if not pubspec.exists():
            return {"error": "pubspec.yaml not found"}
        
        content = pubspec.read_text(encoding='utf-8')
        
        firebase_packages = {
            "firebase_core": "firebase_core" in content,
            "firebase_auth": "firebase_auth" in content,
            "cloud_firestore": "cloud_firestore" in content,
            "firebase_storage": "firebase_storage" in content,
            "firebase_messaging": "firebase_messaging" in content,
            "firebase_analytics": "firebase_analytics" in content,
        }
        
        # Verifica arquivos de configuração
        android_google_services = (self.project_root / "android/app/google-services.json").exists()
        ios_google_services = (self.project_root / "ios/Runner/GoogleService-Info.plist").exists()
        
        return {
            "packages": firebase_packages,
            "android_configured": android_google_services,
            "ios_configured": ios_google_services,
            "status": "ok" if any(firebase_packages.values()) else "not_configured"
        }
    
    def analyze_hive_models(self) -> dict[str, Any]:
        """Analisa modelos Hive"""
        models = []
        
        # Procura por arquivos com @HiveType
        for dart_file in self.lib_path.rglob("*.dart"):
            content = dart_file.read_text(encoding='utf-8')
            
            if "@HiveType" in content:
                # Extrai informações do modelo
                type_pattern = r"@HiveType\(typeId:\s*(\d+)\)"
                class_pattern = r"class\s+(\w+)\s+(?:extends\s+\w+)?"
                field_pattern = r"@HiveField\((\d+)\)\s+(?:final\s+)?(\w+(?:<.+?>)?)\s+(\w+)"
                
                type_id = re.search(type_pattern, content)
                class_name = re.search(class_pattern, content)
                fields = re.findall(field_pattern, content)
                
                if type_id and class_name:
                    models.append({
                        "name": class_name.group(1),
                        "type_id": int(type_id.group(1)),
                        "file": str(dart_file.relative_to(self.project_root)),
                        "fields": [
                            {"index": int(f[0]), "type": f[1], "name": f[2]}
                            for f in fields
                        ]
                    })
        
        return {
            "models": models,
            "count": len(models)
        }
    
    def analyze_isar_models(self) -> dict[str, Any]:
        """Analisa modelos Isar"""
        models = []
        
        # Procura por arquivos com @collection
        for dart_file in self.lib_path.rglob("*.dart"):
            content = dart_file.read_text(encoding='utf-8')
            
            if "@collection" in content:
                # Extrai informações do modelo
                class_pattern = r"@collection\s+class\s+(\w+)"
                
                # Padrões para campos Isar
                id_pattern = r"Id\s+(\w+)\s*="
                index_pattern = r"@Index\([^)]*\)\s+(?:late\s+)?(?:\w+(?:<.+?>)?)\s+(\w+)"
                field_pattern = r"(?:late\s+)?(\w+(?:<.+?>)?)\s+(\w+)(?:\s*=|\s*;)"
                
                class_match = re.search(class_pattern, content)
                
                if class_match:
                    model_name = class_match.group(1)
                    
                    # Analisa campos
                    model_info = {
                        "name": model_name,
                        "file": str(dart_file.relative_to(self.project_root)),
                        "id_field": None,
                        "indexed_fields": [],
                        "fields": []
                    }
                    
                    # ID
                    id_match = re.search(id_pattern, content)
                    if id_match:
                        model_info["id_field"] = id_match.group(1)
                    
                    # Indexes
                    indexes = re.findall(index_pattern, content)
                    model_info["indexed_fields"] = indexes
                    
                    models.append(model_info)
        
        return {
            "models": models,
            "count": len(models),
            "database": "isar"
        }
    
    def analyze_state_management(self) -> dict[str, Any]:
        """Analisa uso de state management"""
        providers = []
        
        # Procura por providers Riverpod
        for dart_file in self.lib_path.rglob("*.dart"):
            content = dart_file.read_text(encoding='utf-8')
            
            if "@riverpod" in content.lower() or "Provider" in content:
                # Extrai providers
                provider_pattern = r"(?:final|var)\s+(\w+)\s*=\s*(\w*Provider)"
                found = re.findall(provider_pattern, content)
                
                for provider_name, provider_type in found:
                    providers.append({
                        "name": provider_name,
                        "type": provider_type,
                        "file": str(dart_file.relative_to(self.project_root))
                    })
        
        return {
            "providers": providers,
            "count": len(providers),
            "type": "riverpod"
        }
    
    def search_code(self, query: str, file_pattern: str = "*.dart") -> dict[str, Any]:
        """Busca código no projeto"""
        results = []
        
        for dart_file in self.lib_path.rglob(file_pattern):
            try:
                content = dart_file.read_text(encoding='utf-8')
                lines = content.splitlines()
                
                for i, line in enumerate(lines, 1):
                    if query.lower() in line.lower():
                        results.append({
                            "file": str(dart_file.relative_to(self.project_root)),
                            "line": i,
                            "content": line.strip(),
                            "context": lines[max(0, i-2):min(len(lines), i+1)]
                        })
            except Exception:
                continue
        
        return {
            "query": query,
            "results": results[:50],  # Limita a 50 resultados
            "total_found": len(results)
        }
    
    def analyze_routing(self) -> dict[str, Any]:
        """Analisa configuração de rotas"""
        routes = []
        
        for dart_file in self.lib_path.rglob("*.dart"):
            content = dart_file.read_text(encoding='utf-8')
            
            if "GoRoute" in content:
                # Extrai rotas GoRouter
                route_pattern = r"GoRoute\s*\([^)]*path:\s*['\"]([^'\"]+)['\"][^)]*name:\s*['\"]([^'\"]+)['\"]"
                found = re.findall(route_pattern, content)
                
                for path, name in found:
                    routes.append({
                        "path": path,
                        "name": name,
                        "file": str(dart_file.relative_to(self.project_root))
                    })
        
        return {
            "routes": routes,
            "count": len(routes),
            "router_type": "go_router"
        }
