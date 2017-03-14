#############################################################################
##
##  CategoriesWithAmbientObjects.gi                   CategoriesWithAmbientObjects package
##
##  Copyright 2016,      Mohamed Barakat, University of Siegen
##                       Kamal Saleh, University of Siegen
##
##  Implementation stuff for categories with ambient objects.
##
#############################################################################

####################################
#
# representations:
#
####################################

DeclareRepresentation( "IsCapCategoryObjectWithAmbientObjectRep",
        IsCapCategoryObjectWithAmbientObject and
        IsAttributeStoringRep,
        [ ] );

DeclareRepresentation( "IsCapCategoryMorphismWithAmbientObjectRep",
        IsCapCategoryMorphismWithAmbientObject and
        IsAttributeStoringRep,
        [ ] );

####################################
#
# families and types:
#
####################################

# new families:
BindGlobal( "TheFamilyOfCategoriesWithAmbientObjects",
        NewFamily( "TheFamilyOfCategoriesWithAmbientObjects" ) );

BindGlobal( "TheFamilyOfMorphismsWithAmbientObject",
        NewFamily( "TheFamilyOfMorphismsWithAmbientObject" ) );

# new types:
BindGlobal( "TheTypeObjectWithAmbientObject",
        NewType( TheFamilyOfCategoriesWithAmbientObjects,
                IsCapCategoryObjectWithAmbientObjectRep ) );

BindGlobal( "TheTypeMorphismWithAmbientObject",
        NewType( TheFamilyOfMorphismsWithAmbientObject,
                IsCapCategoryMorphismWithAmbientObject ) );

####################################
#
# methods for attributes:
#
####################################

##
InstallMethod( EmbeddingInAmbientObject,
               [ IsCapCategoryObjectWithAmbientObjectRep ],

  function( obj )
    local gens, rels;
    
    gens := NormalizedCospan( GeneralizedEmbeddingInAmbientObject( obj ) );
    rels := ReversedArrow( gens );
    
    return PreCompose( Arrow( gens ), ColiftAlongEpimorphism( rels, CokernelProjection( KernelEmbedding( rels ) ) ) );
    
end );

####################################
#
# methods for operations:
#
####################################

##
InstallMethod( CategoryWithAmbientObject,
               [ IsCapCategory ],
               
  function( underlying_monoidal_category )
    local preconditions, category_weight_list, i,
          structure_record, object_constructor, morphism_constructor, 
          category_with_ambient_objects, zero_object;
    
    if not IsFinalized( underlying_monoidal_category ) then
        
        Error( "the underlying category must be finalized" );
        
    elif not IsMonoidalCategory( underlying_monoidal_category ) then
        
        Error( "the underlying category has to be a monoidal category" );
        
    elif not IsAdditiveCategory( underlying_monoidal_category ) then
        
        ## TODO: support the general case
        Error( "only additive categories are supported yet" );
        
    fi;
    
    category_with_ambient_objects := CreateCapCategory( Concatenation( Name( underlying_monoidal_category ), " with ambient objects" ) );
    
    structure_record := rec(
      underlying_category := underlying_monoidal_category,
      category_with_attributes := category_with_ambient_objects
    );
    
    ## Constructors
    object_constructor := CreateObjectConstructorForCategoryWithAttributes(
              underlying_monoidal_category, category_with_ambient_objects, TheTypeObjectWithAmbientObject );
    
    structure_record.ObjectConstructor := function( object, attributes )
        local return_object;
        
        return_object := object_constructor( object, attributes );
        
        SetGeneralizedEmbeddingInAmbientObject( return_object, attributes[1] );
        
        SetObjectWithoutAmbientObject( return_object, object );
        
        return return_object;
        
    end;
    
    structure_record.MorphismConstructor :=
      CreateMorphismConstructorForCategoryWithAttributes(
              underlying_monoidal_category, category_with_ambient_objects, TheTypeMorphismWithAmbientObject );
    
    ##
    category_weight_list := underlying_monoidal_category!.derivations_weight_list;
    
    ## ZeroObject with ambient object
    #preconditions := [ "UniversalMorphismIntoZeroObject",
    #                   "TensorProductOnObjects" ];
    preconditions := [  ];
    
    if ForAll( preconditions, c -> CurrentOperationWeight( category_weight_list, c ) < infinity ) then
        
        zero_object := ZeroObject( underlying_monoidal_category );
        
        structure_record.ZeroObject :=
          function( underlying_zero_object )
              
              return [ AsGeneralizedMorphismByCospan( ZeroMorphism( underlying_zero_object, zero_object ) ) ];
              
          end;
    fi;
    
    ## Left action for DirectSum
    preconditions := [ "LeftDistributivityExpandingWithGivenObjects",
                       "DirectSum", #belongs to LeftDistributivityExpandingWithGivenObjects
                       "PreCompose" ];
    
    if ForAll( preconditions, c -> CurrentOperationWeight( category_weight_list, c ) < infinity ) then
        
        structure_record.DirectSum :=
          function( obj_list, underlying_direct_sum )
            local embeddings_list, underlying_obj_list, structure_morphism;
            
            embeddings_list := List( obj_list, obj -> ObjectAttributesAsList( obj )[1] );
            
            underlying_obj_list := List( obj_list, UnderlyingCell );
            
            structure_morphism := 
              ConcatenationProduct( embeddings_list );
            
            return [ structure_morphism ];
            
          end;
        
    fi;
    
    ## Lift embeddings in ambient objects along monomorphism
    preconditions := [ "IdentityMorphism",
                       "PreCompose",
                       "TensorProductOnMorphismsWithGivenTensorProducts",
                       "TensorProductOnObjects", #belongs to TensorProductOnMorphisms
                       "LiftAlongMonomorphism" ];
    
    if ForAll( preconditions, c -> CurrentOperationWeight( category_weight_list, c ) < infinity ) then
        
        structure_record.Lift :=
          function( mono, range )
            local embedding_of_range;
            
            embedding_of_range := ObjectAttributesAsList( range )[1];
            
            return [ PreCompose( mono, embedding_of_range ) ];
            
          end;
        
    fi;
    
    ## Colift left action along epimorphism
    preconditions := [ "IdentityMorphism",
                       "PreCompose",
                       "TensorProductOnMorphismsWithGivenTensorProducts",
                       "TensorProductOnObjects", #belongs to TensorProductOnMorphisms
                       "ColiftAlongEpimorphism" ];
    
    if ForAll( preconditions, c -> CurrentOperationWeight( category_weight_list, c ) < infinity ) then
        
        structure_record.Colift :=
          function( epi, source )
            local embedding_of_source;
            
            embedding_of_source := ObjectAttributesAsList( source )[1];
            
            return [ PreCompose( PseudoInverse( AsGeneralizedMorphismByCospan( epi ) ), embedding_of_source ) ];
            
          end;
        
    fi;
    
    EnhancementWithAttributes( structure_record );
    
    ##
    InstallMethod( ObjectWithAmbientObject,
                   [ IsGeneralizedMorphismByCospan,
                     IsCapCategory and CategoryFilter( category_with_ambient_objects ) ],
                   
      function( object, attribute_category )
        
        return structure_record.ObjectConstructor( UnderlyingHonestObject( Source( object ) ), [ object ] );
        
    end );
    
    ##
    InstallMethod( MorphismWithAmbientObject,
                   [ IsCapCategoryObjectWithAmbientObject and ObjectFilter( category_with_ambient_objects ),
                     IsCapCategoryMorphism and MorphismFilter( underlying_monoidal_category ),
                     IsCapCategoryObjectWithAmbientObject and ObjectFilter( category_with_ambient_objects ) ],
                   
      function( source, underlying_morphism, range )
        
        return structure_record.MorphismConstructor( source, underlying_morphism, range );
        
    end );
    
    ## TODO: Set properties of category_with_ambient_objects
    
    ADD_FUNCTIONS_FOR_CATEGORY_WITH_AMBIENT_OBJECTS( category_with_ambient_objects );
    
    ## TODO: Logic for category_with_ambient_objects
     
    Finalize( category_with_ambient_objects );
    
    return category_with_ambient_objects;
    
end );

##
InstallGlobalFunction( ADD_FUNCTIONS_FOR_CATEGORY_WITH_AMBIENT_OBJECTS,
  
  function( category )
    ##
    AddIsEqualForObjects( category,
      function( object_with_ambient_object_1, object_with_ambient_object_2 )
        
        return IsCongruentForMorphisms( GeneralizedEmbeddingInAmbientObject( object_with_ambient_object_1 ), GeneralizedEmbeddingInAmbientObject( object_with_ambient_object_2 ) );
        
    end );
    
    ##
    AddIsEqualForMorphisms( category,
      function( morphism_1, morphism_2 )
        
        return IsEqualForMorphisms( UnderlyingCell( morphism_1 ), UnderlyingCell( morphism_2 ) );
        
    end );
    
    ##
    AddIsCongruentForMorphisms( category,
      function( morphism_1, morphism_2 )
        
        return IsCongruentForMorphisms( UnderlyingCell( morphism_1 ), UnderlyingCell( morphism_2 ) );
        
    end );
    
end );

####################################
#
# View, Print, and Display methods:
#
####################################

##
InstallMethod( ViewObj,
        "for an object with an ambient object",
        [ IsCapCategoryObjectWithAmbientObjectRep ],
        
  function( obj )
    
    ViewObj( ObjectWithoutAmbientObject( obj ) );
    Print( " with an ambient object" );
    
end );

##
InstallMethod( ViewObj,
        "for a morphism between objects with ambient objects",
        [ IsCapCategoryMorphismWithAmbientObjectRep ],
        
  function( mor )
    
    ViewObj( UnderlyingCell( mor ) );
    
end );

##
InstallMethod( Display,
        "for an object with an ambient object",
        [ IsCapCategoryObjectWithAmbientObjectRep ],
        
  function( obj )
    
    Display( ObjectWithoutAmbientObject( obj ) );
    
end );

##
InstallMethod( DisplayEmbeddingInAmbientObject,
        "for an object with an ambient object",
        [ IsCapCategoryObjectWithAmbientObjectRep ],
        
  function( obj )
    
    Display( EmbeddingInAmbientObject( obj ) );
    
end );

##
InstallMethod( Display,
        "for a morphism between objects with ambient objects",
        [ IsCapCategoryMorphismWithAmbientObjectRep ],
        
  function( mor )
    
    Display( UnderlyingCell( mor ) );
    
end );