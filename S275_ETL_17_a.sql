WITH CTE_TAB
AS (
    SELECT 

       [area]
      ,[cou]
      ,[dis]
      ,[codist]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[cert]
      ,[bdate]
      ,[byr]
      ,[bmo]
      ,[bday]
      ,[sex]
      ,[hispanic]
      ,[race]
      ,[hdeg]
      ,[hyear]
      ,[acred]
      ,[icred]
      ,[bcred]
      ,[vcred]
      ,[exp]
      ,[camix1]
      ,[ftehrs]
      ,[ftedays]
      ,[certfte]
      ,[clasfte]
      ,[certbase]
      ,[clasbase]
      ,[othersal]
      ,[tfinsal]
      ,[cins]
      ,[cman]
      ,[cbrtn]
      ,[clasflag]
      ,[certflag]
--      ,[ceridate]
      ,[act]
      ,[bldgn]
      ,sum([asspct]) pctass
      ,sum([assfte]) ftetotal
      ,sum([asssal]) saltotal
  FROM [SandBox].[dbo].[raw.S275_17] a
  WHERE [droot] in (31,32,33,34) and act='27' and area = 'L'
  GROUP BY [area]
      ,[cou]
      ,[dis]
      ,[codist]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[cert]
      ,[bdate]
      ,[byr]
      ,[bmo]
      ,[bday]
      ,[sex]
      ,[hispanic]
      ,[race]
      ,[hdeg]
      ,[hyear]
      ,[acred]
      ,[icred]
      ,[bcred]
      ,[vcred]
      ,[exp]
      ,[camix1]
      ,[ftehrs]
      ,[ftedays]
      ,[certfte]
      ,[clasfte]
      ,[certbase]
      ,[clasbase]
      ,[othersal]
      ,[tfinsal]
      ,[cins]
      ,[cman]
      ,[cbrtn]
      ,[clasflag]
      ,[certflag]
      --,[ceridate]
      ,[act]
      ,[bldgn]
)
  SELECT *
	INTO [SandBox].[dbo].[s275_state_17]
	FROM (
	SELECT *,RANK() OVER (PARTITION BY cert ORDER BY ftetotal DESC) N 
    FROM CTE_TAB) M
	WHERE N = 1 and cert is not NULL and ftetotal > 0



--169274H