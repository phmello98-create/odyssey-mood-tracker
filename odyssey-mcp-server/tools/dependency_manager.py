"""
Dependency Manager
Gerencia e analisa dependências do pubspec.yaml
"""

import re
from pathlib import Path
from typing import Any
import yaml


class DependencyManager:
    """Gerenciador de dependências Flutter"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.pubspec_path = project_root / "pubspec.yaml"
        self.lib_path = project_root / "lib"
    
    def get_all_dependencies(self) -> dict[str, Any]:
        """Lista todas as dependências"""
        if not self.pubspec_path.exists():
            return {"error": "pubspec.yaml not found"}
        
        try:
            with open(self.pubspec_path, 'r', encoding='utf-8') as f:
                pubspec = yaml.safe_load(f)
            
            dependencies = pubspec.get('dependencies', {})
            dev_dependencies = pubspec.get('dev_dependencies', {})
            
            # Remove dependências do SDK
            deps = {k: v for k, v in dependencies.items() 
                   if not isinstance(v, dict) or 'sdk' not in v}
            dev_deps = {k: v for k, v in dev_dependencies.items() 
                       if not isinstance(v, dict) or 'sdk' not in v}
            
            return {
                "dependencies": self._format_dependencies(deps),
                "dev_dependencies": self._format_dependencies(dev_deps),
                "total_count": len(deps) + len(dev_deps)
            }
        except Exception as e:
            return {"error": str(e)}
    
    def _format_dependencies(self, deps: dict) -> list[dict[str, Any]]:
        """Formata dependências para exibição"""
        formatted = []
        
        for name, version in deps.items():
            if isinstance(version, dict):
                version_str = version.get('version', 'path/git dependency')
            else:
                version_str = str(version) if version else 'any'
            
            formatted.append({
                "name": name,
                "version": version_str,
                "category": self._categorize_dependency(name)
            })
        
        return formatted
    
    def _categorize_dependency(self, name: str) -> str:
        """Categoriza uma dependência"""
        categories = {
            "UI": ["fl_chart", "lottie", "flutter_svg", "dynamic_color", 
                   "flex_color_scheme", "flutter_staggered_grid_view", "countup"],
            "State Management": ["flutter_riverpod", "riverpod"],
            "Navigation": ["go_router"],
            "Database": ["hive", "hive_flutter", "shared_preferences", "path_provider"],
            "Firebase": ["firebase_core", "firebase_auth", "cloud_firestore", 
                        "firebase_storage", "firebase_messaging", "firebase_analytics"],
            "Notifications": ["awesome_notifications", "timezone"],
            "Media": ["image_picker", "audioplayers", "just_audio", "media_kit"],
            "Network": ["http"],
            "Utils": ["intl", "url_launcher", "uuid", "timeago", "crypto"],
            "Security": ["flutter_secure_storage", "encrypt"],
            "Monetization": ["google_mobile_ads", "in_app_purchase"],
            "Editor": ["appflowy_editor", "flutter_quill"],
            "Auth": ["google_sign_in"],
        }
        
        for category, packages in categories.items():
            if name in packages:
                return category
        
        return "Other"
    
    def find_unused_dependencies(self) -> dict[str, Any]:
        """Encontra dependências não utilizadas"""
        if not self.pubspec_path.exists():
            return {"error": "pubspec.yaml not found"}
        
        try:
            with open(self.pubspec_path, 'r', encoding='utf-8') as f:
                pubspec = yaml.safe_load(f)
            
            dependencies = pubspec.get('dependencies', {})
            
            # Coleta todos os imports do projeto
            all_imports = set()
            for dart_file in self.lib_path.rglob("*.dart"):
                try:
                    content = dart_file.read_text(encoding='utf-8')
                    import_pattern = r"import\s+['\"]package:([^/]+)/"
                    imports = re.findall(import_pattern, content)
                    all_imports.update(imports)
                except Exception:
                    continue
            
            # Verifica quais dependências não são usadas
            unused = []
            for dep_name in dependencies:
                if isinstance(dependencies[dep_name], dict) and 'sdk' in dependencies[dep_name]:
                    continue  # Skip SDK dependencies
                
                if dep_name not in all_imports:
                    # Algumas dependências são usadas de forma especial
                    special_deps = [
                        'firebase_core',  # Usado na inicialização
                        'flutter_launcher_icons',
                        'timezone',  # Usado indiretamente
                        'google_mobile_ads',  # Pode ser configurado mas não usado
                    ]
                    
                    if dep_name not in special_deps:
                        unused.append(dep_name)
            
            return {
                "unused": unused,
                "count": len(unused),
                "note": "Some dependencies may be used indirectly or in configuration"
            }
        except Exception as e:
            return {"error": str(e)}
    
    def get_dependency_graph(self) -> str:
        """Retorna grafo de dependências em formato texto"""
        deps_info = self.get_all_dependencies()
        
        if "error" in deps_info:
            return f"Error: {deps_info['error']}"
        
        output = ["# Dependency Graph\n"]
        
        # Agrupa por categoria
        by_category = {}
        for dep in deps_info.get("dependencies", []):
            category = dep["category"]
            if category not in by_category:
                by_category[category] = []
            by_category[category].append(dep)
        
        for category, deps in sorted(by_category.items()):
            output.append(f"\n## {category}")
            for dep in deps:
                output.append(f"  - {dep['name']} ({dep['version']})")
        
        output.append(f"\n\n**Total**: {deps_info['total_count']} dependencies")
        
        return "\n".join(output)
    
    def check_dependency_conflicts(self) -> dict[str, Any]:
        """Verifica conflitos potenciais de dependências"""
        # Por enquanto, retorna uma estrutura básica
        # Poderia ser expandido para verificar versões conflitantes
        return {
            "conflicts": [],
            "warnings": [],
            "status": "ok"
        }
