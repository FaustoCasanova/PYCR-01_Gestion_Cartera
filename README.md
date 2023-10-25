## Proyecto de Gestion de Cartera

### Resumen
El presente proyecto busca simular el comportamiento de la cartera de créditos de una empresa "x" para luego realizar un análisis exploratorio y extraer información e indicadores relevantes afines
al Area de Crédito y Cobranzas que permitirán una gestion adecuada de la cartera de créditos


### Requisitos de Software y Librerias 
- MYSQL WorkBench Version: 8.0.32
  
- Python version 3.9
  ```
  import pandas as pd
  import numpy as np
  import random
  
  from datetime import timedelta
  import sqlalchemy
  from sqlalchemy import create_engine
  ``` 
     

### Estructura
El proyecto esta dividido en 3 secciones importantes:
1) Python   - Simula los datos y crea las tablas a usar
2) MYSQL    - Analisis exploratorio a partir de las tablas
3) Power BI - Analisis explorarotio pero en un Dashboard 
