Class {
	#name : #BaselineOfPrueba2Mineria,
	#superclass : #BaselineOf,
	#category : #BaselineOfPrueba2Mineria
}

{ #category : #loading }
BaselineOfPrueba2Mineria class >> loadLepiter [
	IceRepository registry  
		detect: [ :aRepository |
			aRepository name = 'prueba2Mineria' ]
		ifFound: [ :aRepository | 
			| defaultDatabase currentProperties |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			currentProperties := defaultDatabase properties.
			currentProperties addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [
			self inform: 'Repository not found.' ]
]

{ #category : #baseline }
BaselineOfPrueba2Mineria >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'Prueba2Mineria'
		]
]
