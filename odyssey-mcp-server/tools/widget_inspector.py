"""
Widget Inspector
Inspeciona widgets e suas hierarquias
"""

import re
from pathlib import Path
from typing import Any


class WidgetInspector:
    """Inspetor de widgets Flutter"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.lib_path = project_root / "lib"
    
    def find_widget_usage(self, widget_name: str) -> dict[str, Any]:
        """Encontra uso de um widget específico"""
        usages = []
        
        for dart_file in self.lib_path.rglob("*.dart"):
            try:
                content = dart_file.read_text(encoding='utf-8')
                lines = content.splitlines()
                
                for i, line in enumerate(lines, 1):
                    if widget_name in line:
                        usages.append({
                            "file": str(dart_file.relative_to(self.project_root)),
                            "line": i,
                            "content": line.strip()
                        })
            except Exception:
                continue
        
        return {
            "widget": widget_name,
            "usages": usages,
            "count": len(usages)
        }
    
    def get_widget_tree(self, file_path: str) -> dict[str, Any]:
        """Extrai árvore de widgets de um arquivo"""
        full_path = self.project_root / file_path
        
        if not full_path.exists():
            return {"error": f"File not found: {file_path}"}
        
        try:
            content = full_path.read_text(encoding='utf-8')
            
            # Encontra o método build
            build_pattern = r"Widget\s+build\s*\([^)]*\)\s*\{((?:[^{}]|\{[^{}]*\})*)\}"
            build_match = re.search(build_pattern, content, re.DOTALL)
            
            if not build_match:
                return {"error": "No build method found"}
            
            build_content = build_match.group(1)
            
            # Extrai widgets comuns
            common_widgets = [
                "Scaffold", "AppBar", "Column", "Row", "Container", "Text",
                "ListView", "GridView", "Stack", "Positioned", "Card",
                "SizedBox", "Padding", "Center", "Expanded", "Flexible"
            ]
            
            found_widgets = {}
            for widget in common_widgets:
                count = build_content.count(widget + "(")
                if count > 0:
                    found_widgets[widget] = count
            
            return {
                "file": file_path,
                "widgets": found_widgets,
                "total_widgets": sum(found_widgets.values())
            }
        except Exception as e:
            return {"error": str(e)}
    
    def analyze_widget_complexity(self, file_path: str) -> dict[str, Any]:
        """Analisa complexidade de um widget"""
        full_path = self.project_root / file_path
        
        if not full_path.exists():
            return {"error": f"File not found: {file_path}"}
        
        try:
            content = full_path.read_text(encoding='utf-8')
            
            # Métricas de complexidade
            nesting_level = self._calculate_nesting_level(content)
            widget_count = content.count("(")
            method_count = len(re.findall(r"(?:Widget|void)\s+\w+\s*\(", content))
            
            complexity = "low"
            if nesting_level > 5 or widget_count > 50:
                complexity = "high"
            elif nesting_level > 3 or widget_count > 30:
                complexity = "medium"
            
            return {
                "file": file_path,
                "nesting_level": nesting_level,
                "widget_count": widget_count,
                "method_count": method_count,
                "complexity": complexity,
                "suggestions": self._generate_complexity_suggestions(nesting_level, widget_count)
            }
        except Exception as e:
            return {"error": str(e)}
    
    def _calculate_nesting_level(self, content: str) -> int:
        """Calcula nível de aninhamento máximo"""
        max_level = 0
        current_level = 0
        
        for char in content:
            if char == '{' or char == '(':
                current_level += 1
                max_level = max(max_level, current_level)
            elif char == '}' or char == ')':
                current_level -= 1
        
        return max_level
    
    def _generate_complexity_suggestions(self, nesting: int, widgets: int) -> list[str]:
        """Gera sugestões baseadas na complexidade"""
        suggestions = []
        
        if nesting > 5:
            suggestions.append("Consider extracting nested widgets into separate methods or classes")
        
        if widgets > 50:
            suggestions.append("Widget tree is complex - consider breaking into smaller components")
        
        return suggestions
