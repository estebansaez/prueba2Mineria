Class {
	#name : #Workflow,
	#superclass : #Object,
	#instVars : [
		'repoOwner',
		'repoName',
		'workflowName',
		'filePath',
		'versions',
		'rawJson'
	],
	#category : #'Prueba2Mineria-Model'
}

{ #category : #'as yet unclassified' }
Workflow class >> fromDictionary: aDict [
    | versionsList |
    versionsList := (aDict at: 'versions') collect: [:each |
        VulnerabilityVersion fromDictionary: each].
    ^ self new
        fileName: (aDict at: 'fileName');
        versions: versionsList;
        yourself.
]

{ #category : #'instance creation' }
Workflow class >> fromJsonDict: aDict filePath: path [
    | history keysOrdered |
    history := aDict at: 'history' ifAbsent: [ Dictionary new ].
    keysOrdered := history keys asSortedCollection.
    ^ self new
        repoOwner: (aDict at: 'repo_owner' ifAbsent: [ 'unknown' ]);
        repoName: (aDict at: 'repo_name' ifAbsent: [ 'unknown' ]);
        workflowName: (aDict at: 'workflow_name' ifAbsent: [ path asString ]);
        filePath: path;
        versions: (keysOrdered collect: [:ts | VulnerabilityVersion fromTimestamp: ts entry: (history at: ts)]);
        rawJson: aDict;
        yourself

]

{ #category : #accessing }
Workflow >> fileName [
    ^ fileName.
]

{ #category : #accessing }
Workflow >> fileName: aString [
    fileName := aString.
]

{ #category : #accessing }
Workflow >> filePath [
    ^ filePath

]

{ #category : #accessing }
Workflow >> filePath: p [
    filePath := p

]

{ #category : #accessing }
Workflow >> fromJsonDict: aDict filePath: path [
    | history keysOrdered |
    history := aDict at: 'history' ifAbsent: [ Dictionary new ].

    keysOrdered := history keys asSortedCollection.

    ^ self new
        repoOwner: (aDict at: 'repo_owner' ifAbsent: [ 'unknown' ]);
        repoName: (aDict at: 'repo_name' ifAbsent: [ 'unknown' ]);
        workflowName: (aDict at: 'workflow_name' ifAbsent: [ path asString ]);
        filePath: path;
        versions: (keysOrdered collect: [:ts |
            VulnerabilityVersion fromTimestamp: ts entry: (history at: ts)
        ]);
        rawJson: aDict;
        yourself
]

{ #category : #'as yet unclassified' }
Workflow >> gtMetricsFor: aView [
    <gtView>
    ^ aView columnedList
        title: 'VulnerabilidadesPorVersion';
        priority: 100;
        items: [ 
            self versions collect: [:ver |
                {
                    ver timestamp.
                    ver vulnerabilities size.
                }
            ]
        ];
        column: 'Version' text: [:row | row first];
        column: 'Vulnerabilities' text: [:row | row second asString];
        yourself.

]

{ #category : #'as yet unclassified' }
Workflow >> gtVersionsFor: aView [
    <gtView>
    ^ aView text
        title: 'Nro Versiones';
        priority: 100;
        text: [
            ('Workflow: ', self workflowName, String cr,
             'Versions: ', self versions size asString) asRopedText
        ].

]

{ #category : #'gt-views' }
Workflow >> gtVersionsOverview: aView [
    <gtView>

    ^ aView explicit
        title: 'Vista_Grafica';
        stencil: [ self visualizarVersions ];
        priority: 100;
        yourself.


]

{ #category : #metrics }
Workflow >> numberOfVersions [
    ^ (self versions) size

]

{ #category : #accessing }
Workflow >> rawJson [
    ^ rawJson

]

{ #category : #accessing }
Workflow >> rawJson: d [
    rawJson := d

]

{ #category : #accessing }
Workflow >> repoName [
    ^ repoName

]

{ #category : #accessing }
Workflow >> repoName: s [
    repoName := s

]

{ #category : #accessing }
Workflow >> repoOwner [
    ^ repoOwner

]

{ #category : #accessing }
Workflow >> repoOwner: s [
    repoOwner := s

]

{ #category : #metrics }
Workflow >> totalVulnerabilities [
    ^ (self versions) inject: 0 into: [:sum :v | sum + (v vulnerabilityCount)]

]

{ #category : #accessing }
Workflow >> versions [
    ^ versions

]

{ #category : #accessing }
Workflow >> versions: aCollection [
    versions := aCollection

]

{ #category : #'as yet unclassified' }
Workflow >> visualizarVersions [
    "Versión robusta y minimal: coloca cajas con posicionamiento manual (wrap).
     - Tamaño = minSize + vulnCount * sizeFactor
     - Color según cantidad total de versiones (versionCount < 5 -> rojo, else verde)
     - Muestra el número dentro de cada caja
     - Devuelve un elemento pannable (puedes desplazar con el ratón).
     No usa layoutes ni llamadas que puedan faltar en tu imagen."
    | container viewportW viewportH currentX currentY maxRowH padding sizeFactor minSize versionCount vulnCounts maxV maxBox boxSpacing zoomable |

    "Parámetros visuales (ajusta si quieres)"
    sizeFactor := 22.   "px por vulnerabilidad"
    minSize := 40.      "tamaño base para todas las cajas"
    boxSpacing := 8.    "espacio entre cajas"
    padding := 12.      "margen interior del lienzo"

    "Información de versiones/vulnerabilidades"
    versionCount := self versions size.
    vulnCounts := (self versions collect: [:v | (v vulnerabilities size) asInteger]).
    maxV := (vulnCounts isEmpty ifTrue: [ 0 ] ifFalse: [ vulnCounts max ]).
    maxBox := (minSize + (maxV * sizeFactor)).

    "Viewport visible (ajusta si quieres una ventana mayor en el inspector)"
    viewportW := 900.
    viewportH := 600.

    "Crear lienzo grande donde posicionar manualmente"
    container := BlElement new.
    container background: Color white.
    container clipChildren: false.
    "Tamaño inicial del lienzo: ancho = max(viewportW, suficiente) ; alto estimado, se actualizará"
    container size: ( ( (maxBox + boxSpacing) * 10 ) max: viewportW ) @ (viewportH * 2).

    "Posicionamiento manual"
    currentX := padding.
    currentY := padding.
    maxRowH := 0.

    "Crear cada caja y ubicarla manualmente con wrap"
    self versions withIndexDo: [:ver :idx |
        | vulnCount boxSize color box textEl titleEl|

        vulnCount := (vulnCounts at: idx) asInteger.
        boxSize := (minSize + (vulnCount * sizeFactor)) rounded.

        "Color según # versiones (tal como definiste)"
        color := (versionCount < 5) ifTrue: [ Color red ] ifFalse: [ Color green ].

        "Crear caja"
        box := BlElement new.
        box size: boxSize @ boxSize.
        box background: color.
        box border: (BlBorder paint: Color black width: 1).
		
		box layout: BlFrameLayout new.
        "----- Encabezado: nombre/fecha de versión -----"
		
		titleEl := BlTextElement new.
		titleEl text: (ver timestamp asRopedText fontSize: 10).
		titleEl constraintsDo: [:c |
    		c frame horizontal alignCenter.
    		c frame vertical alignTop.                    
		].
		box addChild: titleEl.
        
        "Texto centrado dentro de la caja"
       
        textEl := BlTextElement new.
        textEl text: ((vulnCount asString) asRopedText fontSize: 30).
        textEl layout: BlFrameLayout new.
        textEl constraintsDo: [:c |
            c frame horizontal alignCenter.
            c frame vertical alignCenter].
        box addChild: textEl.

        "Si la caja no cabe en la línea visible, hacer wrap (usar viewportW)"
((currentX + boxSize + padding) > viewportW) ifTrue: [
    currentX := padding.
    currentY := currentY + maxRowH + boxSpacing.
    maxRowH := 0.
].
        "ubicar caja"
        box relocate: currentX @ currentY.
        container addChild: box.

        "actualizar punteros"
        currentX := currentX + boxSize + boxSpacing.
        maxRowH := maxRowH max: boxSize.
    ].

    "Ajustar tamaño final del lienzo al contenido real"
    container size: ( ((currentX max: (maxBox + padding)) + padding) max: viewportW ) 
                @ ( ((currentY + maxRowH + padding) max: viewportH) ).


    "Crear elemento zoomable/pannable con viewport definido"
    zoomable := BlZoomableElement new.
    zoomable size: viewportW @ viewportH.
    zoomable clipChildren: false.
    zoomable contentElement: container.


     (Smalltalk at: #RenderUtil) ifNotNil: [
        (RenderUtil respondsTo: #addZoomBehaviorTo:) ifTrue: [
            RenderUtil addZoomBehaviorTo: zoomable
        ]
    ].
    
    ^ zoomable asPannableElement

]

{ #category : #'as yet unclassified' }
Workflow >> visualizeJESUS: aView [
    "Visualiza cada versión como un cuadrado, acomodados de izquierda a derecha;
    al llegar al límite derecho, pasa a otra fila más abajo (horizontal row wrap).
    Incluye zoom y pan."

    | mainContainer currentX currentY maxRowHeight maxX scale baseSize zoomableContainer |
    mainContainer := BlElement new
        background: Color white;
        size: 3000 @ 1300;  "Tamaño base, puedes ajustar"
        clipChildren: false;
        yourself.

    "Componente zoom y pan"
    zoomableContainer := BlZoomableElement new
        size: 1600 @ 800;
        clipChildren: false;
        contentElement: mainContainer;
        yourself.

    scale := self rectangleScaleFactor.      "Por ejemplo, 30"
    baseSize := self baseRectangleSize.      "Por ejemplo, 10"
    maxX := 2400.       "Límite derecho, ajusta según pantalla"
    currentX := 20.
    currentY := 20.
    maxRowHeight := 0.

    self versions do: [ :v |
        | vulnCount size squareElement label1 label2 |
        vulnCount := v vulnerabilityCount asInteger.
        size := baseSize + (vulnCount * scale).

        squareElement := BlElement new
            geometry: BlRectangleGeometry new;
            size: size @ size;
            background: self visualizeColor;
            border: (BlBorder paint: Color black width: 2);
            yourself.

        label1 := BlTextElement new
            text: (('Versión: ', v timestampString) asRopedText
                fontSize: 12; foreground: Color white; bold);
            yourself.
        label2 := BlTextElement new
            text: (('# Vulnerabilidades: ', vulnCount asString) asRopedText
                fontSize: 12; foreground: Color white; bold);
            yourself.

        squareElement addChild: label1.
        label1 relocate: 6 @ 6.
        squareElement addChild: label2.
        label2 relocate: 6 @ (size - 22 max: 6).

        squareElement addEventHandler: (BlEventHandler
            on: BlMouseEnterEvent
            do: [ :evt | squareElement border: (BlBorder paint: Color yellow width: 4) ]).
        squareElement addEventHandler: (BlEventHandler
            on: BlMouseLeaveEvent
            do: [ :evt | squareElement border: (BlBorder paint: Color black width: 2) ]).
        squareElement addEventHandler: (BlEventHandler
            on: BlClickEvent
            do: [ :evt |
                (aView respondsTo: #setObject:)
                    ifTrue: [ aView setObject: v ]
                    ifFalse: [ squareElement phlow spawnObject: v ].
                evt consumed: true ]).

        "==== Posicionamiento manual fila-horizontales ===="
        squareElement relocate: currentX @ currentY.
        "Actualiza el máximo alto en la fila"
        maxRowHeight := maxRowHeight max: size.

        "Avanza a la derecha"
        currentX := currentX + size + 20.

        "¿Saltamos de fila? Si pasamos del borde derecho"
        (currentX + size > maxX) ifTrue: [
            currentX := 20.                       "Volvemos a la izquierda"
            currentY := currentY + maxRowHeight + 22.  "Bajamos"
            maxRowHeight := 0.
        ].
        "==== Fin del posicionamiento fila-horizontal ===="

        mainContainer addChild: squareElement.
    ].

    "Ajusta el tamaño del contenedor grande si quieres (opcional)"
    mainContainer size: (maxX + 100) @ (currentY + maxRowHeight + 80).

    "Permite pan y zoom"
    ^ zoomableContainer asPannableElement
]

{ #category : #metrics }
Workflow >> vulnerabilitiesPerVersion [
    ^ (self versions) collect: [:v | v timestamp -> v vulnerabilityCount]

]

{ #category : #accessing }
Workflow >> workflowName [
    ^ workflowName

]

{ #category : #accessing }
Workflow >> workflowName: s [
    workflowName := s

]
