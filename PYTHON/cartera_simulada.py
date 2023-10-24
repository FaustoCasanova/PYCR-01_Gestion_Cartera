# -*- coding: utf-8 -*-
"""
Created on Tue Oct 17 20:16:32 2023

@author: Fausto Casanova Cedeño

"""

import pandas as pd
import numpy as np
import random
from datetime import timedelta

#---------------------------------------------------------------------------------------------
# Import data

clientes = pd.read_excel("Catastro Grandes Contribuyentes SRI.xlsx")
clientes.info()

#---------------------------------------------------------------------------------------------

# | Tabla 1 clientes |

#---> Eliminando columnas innecesarias
clientes.drop(["JURISDICCIÓN","DESCRIPCIÓN SUBTIPO","DESCRIPCION TIPO"], axis=1, inplace=True)

#---> Ajustando Formato de columnas
clientes.columns = clientes.columns.str.capitalize()
clientes.rename(columns = {"No.":"Cliente_id"}, inplace=True)

#---> Quitando mayusculas de los valores string
names = clientes.columns[clientes.dtypes == "object"]

for name in names:
    clientes[name] = clientes[name].str.capitalize()

#---> Filtrar solo Provincia Pichincha
clientes = clientes[clientes["Provincia"] == "Pichincha"]

#---> Escoger aleatoriamente 50 clientes 
clientes = clientes.sample(50, random_state=20)

#---> Añadiendo informacion adicional
clientes["Contacto"] = "593-xxxxxxxxx"

clientes["Calificacion_asignada"]  = \
    np.random.choice( ["A","B","C"], size=len(clientes), p=[0.7, 0.2, 0.1] )

#---> Reordenar columnas 
clientes = clientes.iloc[:,[0,1,2,5,6,3,4]]

del name , names


#---------------------------------------------------------------------------------------------

# | Tabla 2 Ventas a credito |

#---> \ Creando la tabla y sus campos / 

ITEMS  = ["Pack-A", "Pack-B", "Pack-C"]
PVU    = [150, 250, 300]

NAMES  = ["Transaccion_id","Fecha_transcc","Cliente_id","Factura","Fecha_Factura",
          "Item","Precio_unitario","Cantidad","Subtotal","IVA_12","Total_Factura","Forma_pago"] 


ventas = pd.DataFrame(data    = np.zeros(shape = (5000, len(NAMES)) ) ,
                      columns = NAMES 
                   )


#---> \ Simulando datos de venta /

#-------> Seeds para replicar resultados
np.random.seed(20)
random.seed(20)

#-------> Numero de transaccion
ventas["Transaccion_id"] = range(1,5001,1)

#-------> Transacciones del 1 semestre del 2021
calendar = np.array(pd.date_range("2021-01-01","2021-06-30",freq="B"), dtype='datetime64[D]')
ventas["Fecha_transcc"] = np.random.choice(calendar, size=len(ventas))

#-------> Asignar clientes aleatoriamente
ventas["Cliente_id"] =  np.random.choice(clientes["Cliente_id"], size=len(ventas))

#-------> Asiganar un numero de factura y fecha por transaccion
ventas["Factura"] = ["F-000-0{:03d}".format(num) for num in range(1, len(ventas)+ 1)]

ventas["Fecha_Factura"] = ventas["Fecha_transcc"]

#-------> Asiganr un producto y su valor unitarios
ventas["Item"] = np.random.choice(ITEMS, size=len(ventas))

ventas["Precio_unitario"] = ventas["Item"].map({"Pack-A":150 ,
                                                "Pack-B":250 ,
                                                "Pack-C":350
                                                }
                                           )
 
#-------> Asignar cantidad aleatoria
ventas["Cantidad"] = np.random.randint(low=1, high=10, size=len(ventas))

#-------> Realizar Calculos respectivos 
ventas["Subtotal"] = ventas["Precio_unitario"] * ventas["Cantidad"] 
ventas["IVA_12"]   = ventas["Subtotal"] * 0.12
ventas["Total_Factura"]    = ventas["Subtotal"] + ventas["IVA_12"]

#-------> Forma de Pago Credito
ventas["Forma_pago"] = "Credito"

del calendar , ITEMS , NAMES , PVU


#---------------------------------------------------------------------------------------------

# | Tabla 3 Cartera de Credito |


#---> \ Creando la tabla y sus campos / 

creditos = ventas.iloc[:,[2,3,4,10]].copy()


#---> \ Simulando datos de credito /

#-------> Seeds para replicar resultados
np.random.seed(20)
random.seed(20)

#-------> Numero de credito
creditos["Credit_id"] = range(1,5001,1)

#-------> Monto del credito
creditos["Monto_credito"] = creditos["Total_Factura"]

#-------> Segun politicas se otorga entre 15 y 45 dias de credito
creditos["Fecha_vencimiento"] = creditos["Fecha_Factura"] + pd.to_timedelta(random.randint(15,45), unit='D')

#-------> Reordenar columnas
creditos = creditos.iloc[:,[4,0,1,3,2,5,6]]



#---------------------------------------------------------------------------------------------

# | Tabla 4 Control de Cobros de Creditos  |


#---> \ Simular el comportamiento de pago de creditos / 


#-------> Generador de  Fechas aleatorias entre dos Fechas definidas 
def random_date(start, end):
    """ From: nosklo - StackOverFlow
    This function will return a random datetime between two datetime 
    objects. 
    
    """
    delta = end - start
    int_delta = (delta.days * 24 * 60 * 60) + delta.seconds
    random_second = random.randrange(int_delta)
    return start + timedelta(seconds=random_second)


#-------> Agrupar datos por Fecha de Factura
df_group = creditos.groupby(["Fecha_Factura"], as_index=False)

#-------> Contenedor de grupos
group = {} 

#-------> Probabilidad de que los pagos "vencidos" sean de n dias
np.random.seed(20)
dias_vencido = [15, 30, 45, 60, 90]
probabilidad = [0.65, 0.15, 0.05, 0.05, 0.1]


#-------> Iterador de grupos 
for name , data in df_group:
    
    group[f"{name}"] = data
    
    # Probabilidad de que el pago se haya pagado a tiempo o Vencido
    prob = random.uniform(0.7, 0.8)
    group[f"{name}"]["Categoria"]  = np.random.choice(["A tiempo","Vencido"], size=len(data), p=[prob,1-prob])
    group[f"{name}"]["Fecha_pago"] = 0

    # Para cada grupo asiganamos Fechas de pago simuladas
    for index, row in data.iterrows():
        
        # Si pagó a timepo la Fecha de pago se hara entre la Fecha Facturada y la Fecha de Vencimiento
        if row['Categoria'] == "A tiempo":
            
            start = pd.to_datetime(row['Fecha_Factura'])
            end   = pd.to_datetime(row['Fecha_vencimiento'])
            # Invoca la Funcion random_date
            group[f"{name}"].loc[index,"Fecha_pago"] = random_date(start, end) 
            
        # Si pagó vencido la Fecha de pago se hara fuera de la fecha de vencimiento
        else:
            group[f"{name}"].loc[index,"Fecha_pago"] = row['Fecha_vencimiento'] + \
                                                       pd.to_timedelta(np.random.choice(dias_vencido,
                                                                                        size = 1,
                                                                                        p = probabilidad
                                                                                        )[0] , 
                                                                       unit='D'
                                                                   )                                                   
#-------> Unir grupos en un solo dataframe
temp_cobros = pd.concat(group,axis=0)
temp_cobros = temp_cobros.sort_values(by=["Fecha_pago"])
temp_cobros.reset_index(drop=True, inplace=True)
temp_cobros.info()


#---> \ Crear la Tabla y ajustar sus campos / 

#-------> Eliminar columnas innecesarias
cobros = temp_cobros.iloc[:,[1,0,5,8]].copy() 

#-------> Agregar columnas necesarias
cobros["Cobro_id"] = range(1,5001,1)
cobros["Detalles"] = "Cobranza de Credito"
cobros["Observaciones"] = "Ninguna"

#-------> Renombrar y ordenar columnas
cobros.rename(columns={"Monto_credito":"Monto_cobrado",
                       "Fecha_pago":"Fecha_cobro"}, 
              inplace=True)

cobros = cobros.iloc[:,[4,3,0,5,1,2,6]]


del data , start , end , index , row , prob , probabilidad , name , dias_vencido


#---------------------------------------------------------------------------------------------

# | Exportar Tablas a MYSQL  |

import sqlalchemy
from sqlalchemy import create_engine

"""

# Crear un motor SQLAlchemy
engine = create_engine('mysql+mysqlconnector://root:contraseña@localhost/db_name')

# Insertar el DataFrame en la tabla de MySQL
table_name_1 = 'clientes'
table_name_2 = 'creditos'
table_name_3 = 'cobros'
table_name_4 = 'ventas'

# Exportar y Crear Tablas en MYSQL
clientes.to_sql(name=table_name_1, con=engine, if_exists='replace', index=False)
creditos.to_sql(name=table_name_2, con=engine, if_exists='replace', index=False)
cobros.to_sql(name=table_name_3  , con=engine, if_exists='replace', index=False)
ventas.to_sql(name=table_name_4  , con=engine, if_exists='replace', index=False)

"""













































