#-------------------------------------------------------------------------------------------------------
# DATABASE - cartera 
#-------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------
#					\ Informacion de las Tablas /
-- > Tabla clientes
SELECT * FROM cartera.clientes LIMIT 10		;

-- > Tabla ventas
SELECT * FROM cartera.ventas LIMIT 10		;

-- > Tabla creditos
SELECT * FROM cartera.creditos LIMIT 10		;

-- > Tabla cobros
SELECT * FROM cartera.cobros LIMIT 10		;


#-------------------------------------------------------------------------------------------------------
# 					\ Analisis Exploratorio Parte 1 /

-- > 1) Cuantos creditos se otorgaron por cada mes y cual fue su Monto Total respectivo ?
-- > 2) Cuantos creditos se cobraron por cada mes y  cual fue su Monto Total respectivo ?

-- > 3) Calcular el Monto Acumulado de la cartera de credito por mes 
-- > 4) Calcular el Monto Acumulado de los cobros de credito por mes
-- > 5) Calcular el Saldo Pendiente de cobro al final de cada mes 

-- > 6) Calcular la Cartera Bruta de cada mes donde:
-- >    Cartera_Bruta = Saldo_por_cobrar_mes_anterior + Monto_creditos_mes_actual

-- > 7) Que porcentage de la Cartera fue cobrado cada mes ?   
-- > 8) Que porcentage de la cartera esta pendiente de cobro ?


DROP VIEW IF EXISTS cartera.Explorar_1 ;
CREATE VIEW cartera.Explorar_1 AS
SELECT 
    C1.mes_id , C1.mes , 
    C1.Creditos_dados , C2.Creditos_cobrados ,
    C1.Monto_credito  , C2.Monto_cobrado     ,
        	
	SUM(C1.Monto_credito) OVER (ORDER BY C1.mes_id) AS Cartera_Acumulada ,
    SUM(C2.Monto_cobrado) OVER (ORDER BY C1.mes_id) AS Cobros_Acumulados ,
    SUM(C1.Monto_credito) OVER (ORDER BY C1.mes_id) - SUM(C2.Monto_cobrado) OVER (ORDER BY C1.mes_id) AS Saldo_por_cobrar
FROM
	-- > Subquery 1
	(SELECT
		MONTH(Fecha_Factura) AS mes_id			,
		MONTHNAME(Fecha_Factura) AS mes 		,
		COUNT(Credit_id) AS Creditos_dados  	,
		SUM(Monto_credito) AS Monto_credito
	FROM cartera.creditos
	GROUP BY MONTH(Fecha_Factura) , MONTHNAME(Fecha_Factura) 
	ORDER BY mes_id 
	) AS C1
	
LEFT JOIN 
	-- > Subquery 2
	(SELECT
		MONTH(Fecha_cobro) AS mes_id 			,
		MONTHNAME(Fecha_cobro) AS mes 			,
		COUNT(Credit_id) AS Creditos_cobrados 	,
		SUM(Monto_cobrado) AS Monto_cobrado
	FROM cartera.cobros
	GROUP BY MONTH(Fecha_cobro) , MONTHNAME(Fecha_cobro) 
	HAVING mes_id IN (1,2,3,4,5,6)
	ORDER BY mes_id 
    ) AS C2
-- > Unir Consultas
ON C1.mes_id = C2.mes_id
ORDER BY C1.mes_id ;


# ------------------------------------- > \ Respuestas 1 al 5 / < --------------------------------------
SELECT * 
FROM cartera.Explorar_1 ;


# ------------------------------------- > \ Respuestas 6 al 8 / < --------------------------------------

SELECT 
	mes_id , mes , 
    Cartera_Acumulada , Cobros_Acumulados , Saldo_por_cobrar , Monto_credito ,
    -- > Cartera Bruta
    Monto_credito + LAG(Saldo_por_cobrar,1,0) OVER(ORDER BY mes_id) AS Cartera_Bruta ,
    Monto_cobrado ,
    -- > Porcentage de Cartera Cobrada
    ROUND(
		Monto_cobrado / (Monto_credito + LAG(Saldo_por_cobrar,1,0) OVER(ORDER BY mes_id)) , 
        3 
	) AS Porcentage_Cartera_Cobrada ,
    -- > Porcentage de Cartera Pendiente
	ROUND(
		1 - ( Monto_cobrado / (Monto_credito + LAG(Saldo_por_cobrar,1,0) OVER(ORDER BY mes_id)) ) ,
        3
	) AS Porcentage_Cartera_Pendiente 
    
FROM cartera.Explorar_1 ;


#-------------------------------------------------------------------------------------------------------
# 									\ Analisis Exploratorio Parte 2 /

# Analisis general del comportamiento de pago de clientes 
-- > 9)  Del Monto Total cobrado por mes que Monto      fue cobrado A Tiempo y que cual fue cobrado con Fecha Vencida 
-- > 10) Del Monto Total cobrado por mes que Porcentage fue cobrado A Tiempo y que cual fue cobrado con Fecha Vencida 


# ------------------------------------- > \ Respuestas 9 al 10 / < --------------------------------------
WITH Explorar_2 AS (
SELECT 
	MONTH(C2.Fecha_cobro) AS mes_id  ,
    MONTHNAME(C2.Fecha_cobro) AS mes ,
	C1.Credit_id , C1.Cliente_id  , C1.Total_Factura , C1.Fecha_Factura , C1.Monto_credito , C1.Fecha_vencimiento ,
	C2.Cobro_id  , C2.Fecha_cobro , C2.Monto_cobrado ,
    SUM(C2.Monto_cobrado) OVER(PARTITION BY MONTH(C2.Fecha_cobro) ) AS Total_Cobro_Mensual ,
    CASE 
		WHEN C1.Fecha_vencimiento >= C2.Fecha_cobro THEN "A TIEMPO"
        ELSE "VENCIDO"
    END AS Vencimiento
FROM cartera.creditos    AS C1
LEFT JOIN cartera.cobros AS C2
	ON C1.Credit_id = C2.Credit_id
WHERE MONTH(C1.Fecha_Factura) IN (1,2,3,4,5,6) AND MONTH(C2.Fecha_cobro) IN (1,2,3,4,5,6)
ORDER BY mes_id , C1.Fecha_Factura
)
SELECT mes_id , mes , Vencimiento , 
	SUM(Monto_cobrado) AS Monto_Cobrado ,
    AVG(Total_Cobro_Mensual) AS Total_Cobro_Mensual ,
    -- > Calculo Porcentages
    ROUND(
		SUM(Monto_cobrado)  / AVG(Total_Cobro_Mensual) , 
        3 
	) AS Porcentage_vencimiento
FROM Explorar_2
GROUP BY mes_id , mes , Vencimiento ;


# Analsis de la Cartera Pendiente de Cobro
-- > 11) Del saldo pendiente por cobrar que Monto y cuantos creditos se mantiene Vigente y cual esta Vencido , por mes 
-- > 12) De los Montos Vencidos asignarle una clasificacion en base a los dias vencidos 
-- > 13) Que porcentage de la cartera total representa cada clasificacion ?


# ------------------------------------- > \ Respuestas 11 al 13 / < --------------------------------------
DROP PROCEDURE IF EXISTS cartera.Reportes_Corte ;
DELIMITER //
CREATE PROCEDURE cartera.Reportes_Corte()
BEGIN
    DECLARE contador INT					;
    SET contador = 1						;
	SET @Fecha_corte = DATE("2021-01-31") 	;
    -- > Inicio del Bucle
    WHILE contador <= 6 DO
    
        -- > Inicio de Consulta Principal 
		WITH Explorar_3 AS (
		SELECT 
			MONTH(C1.Fecha_Factura) AS mes_id  , 
            MONTHNAME(C1.Fecha_Factura) AS mes ,
			C1.Credit_id , C1.Cliente_id , C1.Total_Factura , C1.Fecha_Factura , C1.Monto_credito , C1.Fecha_vencimiento ,
			C2.Monto_cobrado ,
			COUNT(C1.Fecha_Factura) OVER (PARTITION BY MONTH(C1.Fecha_Factura)) AS conteo ,
			SUM(C1.Monto_credito) OVER(PARTITION BY MONTH(C1.Fecha_Factura)) AS Cartera_del_Mes ,
            SUM(C1.Monto_credito) OVER() AS Cartera_Total ,
			CASE 
				WHEN C1.Fecha_vencimiento >= @Fecha_corte THEN "VIGENTE"
                WHEN DATEDIFF(@Fecha_corte , C1.Fecha_vencimiento) BETWEEN 1  AND 15 THEN "VENCIDO 01-15"
                WHEN DATEDIFF(@Fecha_corte , C1.Fecha_vencimiento) BETWEEN 16 AND 30 THEN "VENCIDO 16-30"
                WHEN DATEDIFF(@Fecha_corte , C1.Fecha_vencimiento) BETWEEN 31 AND 45 THEN "VENCIDO 31-45"
                WHEN DATEDIFF(@Fecha_corte , C1.Fecha_vencimiento) BETWEEN 46 AND 60 THEN "VENCIDO 46-60"
				ELSE "VENCIDO +60"
			END AS Vencimiento

		FROM 
			-- > Subquery 1
			(SELECT * 
             FROM cartera.creditos
			 WHERE MONTH(Fecha_Factura) BETWEEN 1 AND contador ) AS C1
		LEFT JOIN 
			-- > Subquery 2
			(SELECT * 
             FROM cartera.cobros
			 WHERE MONTH(Fecha_cobro) BETWEEN 1 AND contador ) AS C2
		ON C1.Credit_id = C2.Credit_id
		WHERE C2.Monto_cobrado IS NULL 
		ORDER BY mes_id
		)
        -- > Respuestas
		SELECT mes_id , mes , Vencimiento , 
			SUM(Monto_credito)   AS Monto_Credito	,
			AVG(Cartera_del_Mes) AS Cartera_del_Mes ,
            AVG(Cartera_Total)   AS Cartera_Total 	,
			ROUND( SUM(Monto_credito)  / AVG(Cartera_Total) , 3 ) AS Porcentage_cartera ,
			ROUND(AVG(conteo),0) AS N_Creditos
		FROM Explorar_3
		GROUP BY mes_id , mes , Vencimiento 
        ORDER BY mes_id , Monto_Credito DESC  ;
		-- > Final de Consulta Principal
        
		SET @Fecha_corte = DATE_ADD(DATE("2021-01-31"), INTERVAL contador MONTH) ; 
		SET contador = contador + 1 ;
        
    END WHILE ;
    -- > Fin del Bucle
END //
DELIMITER ;

# Invocar Procedure
CALL cartera.Reportes_Corte() ;


#-------------------------------------------------------------------------------------------------------
# 									\ Analisis Exploratorio Parte 3 /
# Analizar Clientes
# 14) Quienes son el Top 5 de clientes que mas solicitan creditos por mes
# 15) Cual es el Top 5 de clientes con mejores Promedios de pago en este semestre
# 16) Cual es el Top 5 de clientes con peores  Promedios de pago en este semestre


# ------------------------------------- > \ Respuestas 14 / < --------------------------------------
WITH Explorar_4 AS (
SELECT 
	MONTH(Fecha_Factura) AS mes_id ,
    MONTHNAME(Fecha_Factura) AS mes ,
    Cliente_id ,
    COUNT(Cliente_id) AS N_Creditos 
FROM cartera.creditos
GROUP BY MONTH(Fecha_Factura) , MONTHNAME(Fecha_Factura)  , Cliente_id 
ORDER BY mes_id
)
SELECT R1.*
FROM (SELECT * ,
		DENSE_RANK() OVER (PARTITION BY mes_id ORDER BY N_Creditos DESC ) AS Ranked ,
        ROW_NUMBER() OVER (PARTITION BY mes_id ORDER BY N_Creditos DESC ) AS row_id 
	  FROM Explorar_4 ) AS R1 
WHERE row_id <= 5  ;


# ------------------------------------- > \ Respuestas 15 / < --------------------------------------

WITH Explorar_5 AS (
SELECT 
	C1.Cliente_id  , 
    SUM(C2.Monto_cobrado) AS Monto_cobrado ,
    AVG(DATEDIFF(C2.Fecha_cobro , C1.Fecha_vencimiento)) AS Dias_vencimiento
FROM cartera.creditos    AS C1
LEFT JOIN cartera.cobros AS C2
	ON C1.Credit_id = C2.Credit_id
WHERE MONTH(C1.Fecha_Factura) IN (1,2,3,4,5,6) AND MONTH(C2.Fecha_cobro) IN (1,2,3,4,5,6)
GROUP BY C1.Cliente_id 
)
SELECT R2.* 
FROM (SELECT * ,
          DENSE_RANK() OVER (ORDER BY Dias_vencimiento ASC) AS Ranked,
          ROW_NUMBER() OVER (ORDER BY Dias_vencimiento ASC) AS row_id
	  FROM Explorar_5
      ) AS R2
WHERE R2.row_id <= 5 ;


# ------------------------------------- > \ Respuestas 16 / < --------------------------------------
WITH Explorar_6 AS (
SELECT 
	C1.Cliente_id  , 
    SUM(C2.Monto_cobrado) AS Monto_cobrado ,
    AVG(DATEDIFF(C2.Fecha_cobro , C1.Fecha_vencimiento)) AS Dias_vencimiento
FROM cartera.creditos    AS C1
LEFT JOIN cartera.cobros AS C2
	ON C1.Credit_id = C2.Credit_id
WHERE MONTH(C1.Fecha_Factura) IN (1,2,3,4,5,6) AND MONTH(C2.Fecha_cobro) IN (1,2,3,4,5,6)
GROUP BY C1.Cliente_id 
)
SELECT R2.* 
FROM (SELECT * ,
          DENSE_RANK() OVER (ORDER BY Dias_vencimiento DESC) AS Ranked,
          ROW_NUMBER() OVER (ORDER BY Dias_vencimiento DESC) AS row_id
	  FROM Explorar_6
      ) AS R2
WHERE R2.row_id <= 5 ;
