<#
.SYNOPSIS
Desarrollo de un juego en el cual el jugador tiene que ingresar una cantidad de palabras inidicadas en una velocidad determinada.

.DESCRIPTION
El script detecta la cantidad de palabras indicadas por el jugador en la llamada y se dirige a buscarlas a una ruta determinada[en caso de no ser así, va a una ruta por defecto] y las va mostrando en un orden especificado por el usuario, por un tiempo determinado, luego informa el puntaje y lo guarda en un registro de mejores tiempos si el usuario así lo especifica.

.PARAMETER cantPalabras
[Obligatorio]La cantidad de palabras que mostrará el script para que el usuario siga jugando[min: 2 | max: 10].

.PARAMETER rutaPalabras
[Opcional]La ruta donde se encuentran las palabras a mostrar[Si este parámetro es null entonces por def: '.\palabras.txt' (si hay tiempos, debe mostrarlos)].El formato del archivo es [Palabra]\n[Palabra]..

.PARAMETER rutaTiempos
[Opcional]La ruta de donde se encuentran los tiempos a mostrar[Si se ingresa una ruta debe pedirse el nombre del jugador]. El formato del archivo es [Jugador],[Tiempo]\n[Jugador],[Tiempo]..

.PARAMETER Ale
[Obligatorio 1-3]Switch que determina el orden en que las palabras son leidas del archivo[Si se ingresa este parametro, el orden es Aleatorio.

.PARAMETER Asc
[Obligatorio 1-3]Switch que determina el orden en que las palabras son leidas del archivo[Si se ingresa este parametro, el orden es Ascendente.

.PARAMETER Desc
[Obligatorio 1-3]Switch que determina el orden en que las palabras son leidas del archivo[Si se ingresa este parametro, el orden es Descendente.

.EXAMPLE
D:\Agustin\Universidad\Sistemas Operativos\Trabajos Practicos\PowerShell\2C 2018\3er TP\bolty.ps1 11 ./mis_palabras.txt ./tiempos.txt -Ale

En este caso no respetó el minimo|maximo de la cantidad de palabras a mostrar, se detuvo la ejecución.

.EXAMPLE
D:\Agustin\Universidad\Sistemas Operativos\Trabajos Practicos\PowerShell\2C 2018\3er TP\bolty.ps1 5 -Desc

En este caso se ingresa solo la cantidad de palabras y el orden, el script funciona correctamente, indicando al final, si lo hay, el registro de tiempos.
#>
<#
    bolty-fingers.ps1-Trabajo Practico Nro.1-Ejercicio 3
    Primera Entrega
	Magliano, Agustin Gabriel - DNI 39.744.938
	Zambianchi, Nicolás Ezequiel - DNI 39.770.752
	Rosmirez, Juan - DNI 40.010.264
	Arias, Pablo - DNI 32.340.341
	Feito, Gustavo - DNI 27.027.190
#>

Param(
        [Parameter(Position = 1, Mandatory = $true)][Int]$_cantPalabras,
        [Parameter(Position = 2, Mandatory = $false)][AllowEmptyString()][String]$_rutaPalabras = '',
        [Parameter(Position = 3, Mandatory = $false)][AllowEmptyString()][String]$_rutaTiempos = '',
        [Parameter(Mandatory = $false,ParameterSetName='Ale')][Switch]$Ale,
        [Parameter(Mandatory = $false,ParameterSetName='Asc')][Switch]$Asc,
        [Parameter(Mandatory = $false,ParameterSetName='Desc')][Switch]$Desc
      )

###################
#Variables Globales
###################

$nombreJugadorTiempo = $null
$vectorTiempos = New-Object System.Collections.ArrayList
$modoOrdenamiento = ""
$vectorPalabras = @()
$relojContador = New-Object System.Diagnostics.Stopwatch
$relojContadorPalabra = New-Object System.Diagnostics.Stopwatch
$valorRespuesta = ""
$puntajeJugador = 0
$estadisticaTiempoMin = 0
$estadisticaTiempoSeg = 0
$estadisticaTiempoTotal = 0
$estadisticaTiempoMinProm = 0
$estadisticaTiempoSegProm = 0
$estadisticaTiempoPalabras = @{}
$cantidadLetrasTipeadas = 0
$estadisticaTeclasSeg = 0
$perdida = $false

######################
#Se validan parámetros
######################

    if ($_cantPalabras -lt 2 -or $_cantPalabras -gt 10){
      Write-Error 'La cantidad de palbras min|max para iniciar el juego es incorrecta. Ejecute el script con Get-Help para obtener ayuda.'
      return
    }
    
    if([string]::IsNullOrEmpty($_rutaPalabras))
    {
       $rutaPalabrasBase = Get-Location 
       $_rutaPalabras = "$rutaPalabrasBase"+"\palabras.txt"
    }
    else
    {
        $extension = $_rutaPalabras.Split('\')[-1]
        $rutaPalabrasBase = Get-Location
        $_rutaPalabras = "$rutaPalabrasBase"+"\"+"$extension"
    }
    if($(Test-Path $_rutaPalabras) -eq $false)
    {
            Write-Error "La ruta $_rutaPalabras no corresponde a una ruta válida o la misma no existe intente con otra ruta. Ejecute el script con Get-Help para obtener ayuda."
            return
    }
    if(-not ([string]::IsNullOrEmpty($_rutaTiempos)))
    {
        $extensionT = $_rutaTiempos.Split('\')[-1]
        $rutaTiemposBase = Get-Location
        $_rutaTiempos = "$rutaTiemposBase"+"\"+"$extensionT"
        if($(Test-Path $_rutaTiempos) -eq $false)
        {
            Write-Error "La ruta $_rutaTiempos no corresponde a una ruta válida o la misma no existe intente con otra ruta. Ejecute el script con Get-Help para obtener ayuda."
            return
        }
        $nombreJugadorTiempo = Read-Host -Prompt 'Ingrese el nombre del jugador'
        $vectorTiempos = Get-Content -Path $_rutaTiempos
    }else
    {
        $_rutaTiempos = ""
    }
    
    switch ($psCmdLet.ParameterSetName) {
        "Ale" {

        }

        "Asc" {

        }

        "Desc" {

        }
        
        default { 
            Write-Error "No se especificó modo de ordenamiento del archivo de palabras. Ejecute el script con Get-Help para obtener ayuda."
            return
        }
    }

###########################
#Recolección de Información
###########################

Write-Verbose 'Se lee el archivo de palabras y se almacenan en un array, para eso me fijo si la cantidad de palabras es >= a la indicada.'

$vectorPalabras = Get-Content -Path $_rutaPalabras

if($vectorPalabras.Count -lt $_cantPalabras){
    Write-Error 'La cantidad de palabras ingresada supera a las almacenadas en la base de datos, ingrese una cantidad menor.'
    return
}

Write-Verbose 'El vector de tiempos, de existir, ya se cargó en la verificación de la ruta.'
Write-Verbose 'El reloj está definido en parámetros globales y se iniciará cuando comience el juego.'

###########
#Desarrollo
###########

Clear-Host
Write-Verbose 'Comienzo a mostrar las palabras en un for por la cantidad de palabras por un tiempo determinado contandolo, esperando al usuario.'
Write-Verbose 'Antes veo que opcion eligio el usuario para mostrar las palabras. y ordeno el vector en base a eso'
if ($Ale.IsPresent)
{
    $vectorPalabras = $vectorPalabras | Sort-Object {Get-Random}

}elseif($Asc.IsPresent)
{
    $vectorPalabras = $vectorPalabras | Sort
}else
{
    $vectorPalabras = $vectorPalabras | Sort
    [Array]::Reverse($vectorPalabras)
}

for ($i=0; $i -lt $_cantPalabras; $i++)
{
    Write-Output "`n ################################`n |                              |"
    Write-Output "            BIENVENIDO          |`n |                              |"
    Write-Output " ################################`n"
    Start-Sleep -Seconds 0.2
    Write-Output "`nPalabra $($i+1)"
    Write-Output "_______`n"
    Write-Output $vectorPalabras[$i]
    Write-Output "`n"
    $relojContadorPalabra.Start()
    $relojContador.Start()
    $valorRespuesta = Read-Host -Prompt "Ingrese la palabra"
    $relojContador.Stop()
    $relojContadorPalabra.Stop()
    if ($valorRespuesta -ceq $vectorPalabras[$i])
    {
        $puntajeJugador += 1
        Clear-Host
        $cantidadLetrasTipeadas += $valorRespuesta.Length
        $estadisticaTiempoPalabras.Add($Valorrespuesta,[Math]::Round($relojContadorPalabra.Elapsed.TotalSeconds,2))
        $relojContadorPalabra.Reset()
    }else
    {
        $valorCorrecto = $vectorPalabras[$i]
        Clear-Host
        Write-Output "`nPerdiste! La palabra ingresada fue: | $valorRespuesta | pero la palabra correcta era: | $valorCorrecto |."
        $perdida = $true
        break
    }
}

Write-Verbose 'Se calculan las estadísticas para ser mostradas al jugador.'
$estadisticaTiempoMin = $relojContador.Elapsed.Minutes
$estadisticaTiempoSeg = $relojContador.Elapsed.Seconds
$estadisticaTiempoTotal = [Math]::Round($relojContador.Elapsed.TotalSeconds,0)
$estadisticaTiempoMinProm = [Math]::Round($estadisticaTiempoMin/$_cantPalabras,2)
$estadisticaTiempoSegProm = [Math]::Round($estadisticaTiempoSeg/$_cantPalabras,2)
$estadisticaTeclasSeg = [Math]::Round($cantidadLetrasTipeadas/$relojContador.Elapsed.TotalSeconds,2)

Write-Output "`n #####################################`n |                                   |"
Write-Output " |           JUEGO TERMINADO         |`n |                                   |"
Write-Output " #####################################`n"
Write-Output "     _____________________________"
Write-Output "    |         Estadísticas        |"
Write-Output "    |_____________________________|`n    |                             |"
Write-Output "    | Jugador: $nombreJugadorTiempo`n    |                        "
Write-Output "    |-----------------------------|`n    |                        "
Write-Output "    | Tiempo Total: $estadisticaTiempoMin Min: $estadisticaTiempoSeg Seg`n    |                        "
Write-Output "    |-----------------------------|`n    |                        "
Write-Output "    | Tiempo Prom: $estadisticaTiempoMinProm Min: $estadisticaTiempoSegProm Seg`n    |                        "
Write-Output "    |-----------------------------|`n    |        | Palabras |`n    |        |__________|"
for ($i = 0; $i -lt $puntajeJugador ; $i++) {
    "    |                             |`n    | " + $vectorPalabras[$i] + " -> Tiempo: " + $estadisticaTiempoPalabras.Item($vectorPalabras[$i])
}
Write-Output "    |`n    |-----------------------------|`n    |                        "
Write-Output "    | Teclas p/seg: $estadisticaTeclasSeg`n    |                        "
Write-Output "    |-----------------------------|`n    |"
Write-Output "    | Puntaje: $puntajeJugador pts"
Write-Output "    |_____________________________|`n"

Write-Verbose 'Por último se verifica, si el jugador no perdió, el puntaje obtenido en el archivo de tiempos[de haberse especificado] y se informa el ranking del jugador'
if (-not $_rutaTiempos -eq "")
{
    $vectorTiempos = Get-Content -Path $_rutaTiempos -TotalCount 3
    if (-not $perdida)
    {
        if ($vectorTiempos.Count -lt 3)
        {
            Write-Debug 'Se cumplió la condición'
            Out-File -FilePath $_rutaTiempos -InputObject "$nombreJugadorTiempo,$estadisticaTiempoTotal" -Append
            $vectorTiempos += "$nombreJugadorTiempo,$estadisticaTiempoTotal"

            Write-Verbose 'Ordeno el vector para mostrar'
            for($i=0; $i -lt $vectorTiempos.Count; $i++)
            {
                for($j=$i; $j -lt $vectorTiempos.Count; $j++)
                {
                    if ($vectorTiempos[$j] -gt $vectorTiempos[$j+1])
                    {
                        $auxiliar = "$vectorTiempos[$j+1]"
                        $vectorTiempos.Replace("$vectorTiempos[$j+1]","$vectorTiempos[$j]")
                        $vectorTiempos.Replace("$vectorTiempos[$j]", "$auxiliar")
                    }
                }
            }
            $longitudVectorTiempos = $vectorTiempos.Count
        }else
        {
            Write-Debug 'No se cumplió la condición'
            $index = 0
            Foreach ($record in $vectorTiempos)
            {
                $tiempoJugadorRecord = $record.Split(',')[1]
                if ($estadisticaTiempoTotal -lt $tiempoJugadorRecord)
                {
                    $vectorTiempos[$index] = "$nombreJugadorTiempo,$estadisticaTiempoTotal"
                    $vectorTiempos | Set-Content $_rutaTiempos
                    Write-Debug "Reemplazo $record por $nombreJugadorTiempo,$estadisticaTiempoTotal"
                    break;
                }
                $index++
            }
        }   
    }
    
    Write-Output "`n     _____________________________"
    Write-Output "    |        Mejores Tiempos      |"
    Write-Output "    |_____________________________|`n    |                             |"
    Foreach ($record in $vectorTiempos)
    {
        Write-Output "    |                             |`n    |   $record Seg"
    }
    Write-Output "    |_____________________________|`n"
}