/*
 * Human Tasks:
 * 1. Ensure kotlinx.serialization plugin is enabled in app/build.gradle
 * 2. Verify kotlinx.serialization dependency version 1.5+ is included
 * 3. Ensure proper internet permissions are set in AndroidManifest.xml
 */

package com.founditure.android.data.remote.dto

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import com.founditure.android.domain.model.Furniture
import com.founditure.android.data.remote.dto.LocationDto

/**
 * Data Transfer Object for furniture item information with serialization support.
 * 
 * Addresses requirements:
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - AI/ML Infrastructure (1.2 Scope/Core System Components/3. AI/ML Infrastructure)
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 */
@Serializable
data class FurnitureDto(
    @SerialName("id")
    val id: String,
    
    @SerialName("user_id")
    val userId: String,
    
    @SerialName("title")
    val title: String,
    
    @SerialName("description")
    val description: String,
    
    @SerialName("category")
    val category: String,
    
    @SerialName("condition")
    val condition: String,
    
    @SerialName("dimensions")
    val dimensions: Map<String, Double>,
    
    @SerialName("material")
    val material: String,
    
    @SerialName("is_available")
    val isAvailable: Boolean,
    
    @SerialName("ai_metadata")
    val aiMetadata: Map<String, @Serializable(with = AnySerializer::class) Any>,
    
    @SerialName("location")
    val location: LocationDto,
    
    @SerialName("created_at")
    val createdAt: Long,
    
    @SerialName("expires_at")
    val expiresAt: Long
) {
    /**
     * Converts DTO to domain model Furniture object.
     * Implements requirement: Offline-first Architecture by providing proper data mapping
     * for local storage.
     */
    fun toDomainModel(): Furniture {
        return Furniture(
            id = id,
            userId = userId,
            title = title,
            description = description,
            category = category,
            condition = condition,
            dimensions = dimensions,
            material = material,
            isAvailable = isAvailable,
            aiMetadata = aiMetadata,
            location = location.toDomainModel(),
            createdAt = createdAt,
            expiresAt = expiresAt
        )
    }

    companion object {
        /**
         * Creates DTO from domain model Furniture instance.
         * Implements requirement: Furniture Listing Management by providing proper
         * serialization for network transfer.
         */
        fun fromDomainModel(furniture: Furniture): FurnitureDto {
            return FurnitureDto(
                id = furniture.id,
                userId = furniture.userId,
                title = furniture.title,
                description = furniture.description,
                category = furniture.category,
                condition = furniture.condition,
                dimensions = furniture.dimensions,
                material = furniture.material,
                isAvailable = furniture.isAvailable,
                aiMetadata = furniture.aiMetadata,
                location = LocationDto.fromDomainModel(furniture.location),
                createdAt = furniture.createdAt,
                expiresAt = furniture.expiresAt
            )
        }
    }
}

/**
 * Custom serializer for handling Any type in aiMetadata.
 * Implements requirement: AI/ML Infrastructure by supporting flexible AI metadata serialization.
 */
@Serializable
private object AnySerializer : kotlinx.serialization.KSerializer<Any> {
    override val descriptor = kotlinx.serialization.descriptors.SerialDescriptor(
        "kotlin.Any",
        kotlinx.serialization.descriptors.PrimitiveKind.STRING
    )

    override fun serialize(encoder: kotlinx.serialization.encoding.Encoder, value: Any) {
        when (value) {
            is String -> encoder.encodeString(value)
            is Number -> encoder.encodeDouble(value.toDouble())
            is Boolean -> encoder.encodeBoolean(value)
            is List<*> -> {
                val compositeEncoder = encoder.beginCollection(descriptor, value.size)
                value.forEachIndexed { index, item ->
                    compositeEncoder.encodeSerializableElement(
                        descriptor,
                        index,
                        this,
                        item ?: "null"
                    )
                }
                compositeEncoder.endStructure(descriptor)
            }
            else -> encoder.encodeString(value.toString())
        }
    }

    override fun deserialize(decoder: kotlinx.serialization.encoding.Decoder): Any {
        return try {
            decoder.decodeDouble()
        } catch (e: Exception) {
            try {
                decoder.decodeBoolean()
            } catch (e: Exception) {
                decoder.decodeString()
            }
        }
    }
}