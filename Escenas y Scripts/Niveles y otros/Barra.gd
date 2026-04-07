extends Sprite


export(float) var tiempo_caida = 2.0          
export(float) var tiempo_espera_abajo = 0.5    
export(float) var tiempo_espera_arriba = 0.5   
export(float) var distancia_caida = 100.0     
export(float) var delay_inicial = 0.0        
export(bool) var activo = true                 
export(bool) var auto_iniciar = true         

export(bool) var subida_instantanea = true     

export(Texture) var textura_barra setget set_textura_barra

enum Estado { 
	ESPERANDO_INICIO, 
	BAJANDO, 
	ESPERANDO_ABAJO, 
	SUBIENDO, 
	ESPERANDO_ARRIBA 
}

var estado_actual = Estado.ESPERANDO_INICIO
var posicion_inicial = Vector2()
var posicion_inferior = Vector2()
var tiempo_transcurrido = 0.0
var timer_delay = Timer.new()

func _ready():
	if textura_barra:
		texture = textura_barra
	
	posicion_inicial = position
	posicion_inferior = position + Vector2(0, distancia_caida)
	add_child(timer_delay)
	timer_delay.connect("timeout", self, "_on_delay_timeout")
	
	if auto_iniciar:
		if delay_inicial > 0:
			iniciar_con_delay(delay_inicial)
		else:
			iniciar_movimiento()

func _process(delta):
	if not activo:
		return
	
	if estado_actual == Estado.BAJANDO:
		tiempo_transcurrido += delta
		var progreso = min(tiempo_transcurrido / tiempo_caida, 1.0)
		var t = ease(progreso, 0.5) 
		
		position = posicion_inicial.linear_interpolate(posicion_inferior, t)
		if progreso >= 1.0:
			cambiar_estado(Estado.ESPERANDO_ABAJO)
			tiempo_transcurrido = 0.0
	
	elif estado_actual == Estado.SUBIENDO and not subida_instantanea:
		tiempo_transcurrido += delta
		var progreso = min(tiempo_transcurrido / tiempo_caida, 1.0)
		
		var t = ease(progreso, 0.5)
		position = posicion_inferior.linear_interpolate(posicion_inicial, t)
		
		if progreso >= 1.0:
			cambiar_estado(Estado.ESPERANDO_ARRIBA)
			tiempo_transcurrido = 0.0

func cambiar_estado(nuevo_estado):
	estado_actual = nuevo_estado
	
	if nuevo_estado == Estado.ESPERANDO_ABAJO:
		if tiempo_espera_abajo > 0:
			iniciar_timer_espera(tiempo_espera_abajo)
		else:
			cambiar_estado(Estado.SUBIENDO)
	
	elif nuevo_estado == Estado.SUBIENDO:
		if subida_instantanea:
			position = posicion_inicial
			cambiar_estado(Estado.ESPERANDO_ARRIBA)
		else:
			tiempo_transcurrido = 0.0
	
	elif nuevo_estado == Estado.ESPERANDO_ARRIBA:
		if tiempo_espera_arriba > 0:
			iniciar_timer_espera(tiempo_espera_arriba)
		else:
			cambiar_estado(Estado.BAJANDO)
	
	elif nuevo_estado == Estado.BAJANDO:
		tiempo_transcurrido = 0.0

func iniciar_timer_espera(tiempo):
	timer_delay.wait_time = tiempo
	timer_delay.start()

func _on_delay_timeout():
	if estado_actual == Estado.ESPERANDO_ABAJO:
		cambiar_estado(Estado.SUBIENDO)
	elif estado_actual == Estado.ESPERANDO_ARRIBA:
		cambiar_estado(Estado.BAJANDO)

func iniciar_movimiento():
	activo = true
	estado_actual = Estado.BAJANDO
	tiempo_transcurrido = 0.0
	set_process(true)

func iniciar_con_delay(delay):
	timer_delay.wait_time = delay
	timer_delay.start()

func detener_movimiento():
	activo = false
	set_process(false)
	timer_delay.stop()

func pausar_movimiento():
	activo = false
	set_process(false)

func reanudar_movimiento():
	activo = true
	set_process(true)

func resetear_posicion():
	position = posicion_inicial
	estado_actual = Estado.ESPERANDO_INICIO
	tiempo_transcurrido = 0.0

func bajar_instantaneo():
	position = posicion_inferior

func subir_instantaneo():
	position = posicion_inicial

func set_textura_barra(nueva_textura):
	textura_barra = nueva_textura
	texture = nueva_textura
