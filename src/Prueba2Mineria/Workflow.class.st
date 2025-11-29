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


    
    ^ zoomable asPannableElement

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
