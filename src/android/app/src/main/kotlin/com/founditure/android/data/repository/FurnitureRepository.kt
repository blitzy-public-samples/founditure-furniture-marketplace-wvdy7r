/*
 * Human Tasks:
 * 1. Configure network security config for API communication
 * 2. Set up proper database migration strategy when modifying entities
 * 3. Verify proper error handling for network failures
 * 4. Ensure proper cleanup of temporary image files
 */

package com.founditure.android.data.repository

import com.founditure.android.data.local.dao.FurnitureDao
import com.founditure.android.data.remote.api.FurnitureService
import com.founditure.android.domain.model.Furniture
import com.founditure.android.data.local.entity.FurnitureEntity
import com.founditure.android.data.remote.dto.FurnitureDto
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.flowOn
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody

/**
 * Repository implementation that coordinates furniture data operations between local database,
 * remote API, and domain layer, implementing offline-first architecture with synchronization capabilities.
 *
 * Addresses requirements:
 * - Offline-first Architecture (1.2 Scope/Core System Components/1. Mobile Applications)
 * - Furniture Listing Management (1.2 Scope/Core System Components/2. Backend Services)
 * - Location Services (1.2 Scope/Core System Components/2. Backend Services)
 */
@Singleton
class FurnitureRepository @Inject constructor(
    private val furnitureDao: FurnitureDao,
    private val furnitureService: FurnitureService
) {
    /**
     * Retrieves a furniture item by ID with offline-first strategy.
     * First emits local data if available, then fetches and updates from remote.
     *
     * @param id Unique identifier of the furniture item
     * @return Flow emitting the furniture item or null if not found
     */
    fun getFurnitureById(id: String): Flow<Furniture?> = furnitureDao
        .getFurnitureById(id)
        .map { entity -> entity?.toDomainModel() }
        .combine(
            fetchRemoteFurnitureById(id)
        ) { local, remote ->
            remote ?: local
        }
        .catch { e ->
            // Log error and emit local data only
            e.printStackTrace()
            emitAll(furnitureDao.getFurnitureById(id).map { it?.toDomainModel() })
        }
        .flowOn(Dispatchers.IO)

    /**
     * Retrieves all furniture items with synchronization.
     * Implements offline-first pattern with background sync.
     *
     * @return Flow emitting list of all furniture items
     */
    fun getAllFurniture(): Flow<List<Furniture>> = furnitureDao
        .getAllFurniture()
        .map { entities -> entities.map { it.toDomainModel() } }
        .combine(
            fetchRemoteFurnitureList()
        ) { local, remote ->
            remote ?: local
        }
        .catch { e ->
            e.printStackTrace()
            emitAll(furnitureDao.getAllFurniture().map { entities ->
                entities.map { it.toDomainModel() }
            })
        }
        .flowOn(Dispatchers.IO)

    /**
     * Searches for furniture items near a specific location.
     * Implements location-based search with offline support.
     *
     * @param latitude Geographic latitude
     * @param longitude Geographic longitude
     * @param radius Search radius in kilometers
     * @return Flow emitting list of nearby furniture items
     */
    fun searchFurnitureNearLocation(
        latitude: Double,
        longitude: Double,
        radius: Double
    ): Flow<List<Furniture>> = furnitureDao
        .getFurnitureNearLocation(latitude, longitude, radius * radius)
        .map { entities -> entities.map { it.toDomainModel() } }
        .combine(
            fetchRemoteFurnitureNearLocation(latitude, longitude, radius)
        ) { local, remote ->
            remote ?: local
        }
        .catch { e ->
            e.printStackTrace()
            emitAll(furnitureDao.getFurnitureNearLocation(
                latitude,
                longitude,
                radius * radius
            ).map { entities ->
                entities.map { it.toDomainModel() }
            })
        }
        .flowOn(Dispatchers.IO)

    /**
     * Creates a new furniture listing with offline support.
     * Saves locally first, then syncs with remote when possible.
     *
     * @param furniture Furniture item to create
     * @return Created furniture item
     */
    suspend fun createFurniture(furniture: Furniture): Furniture = withContext(Dispatchers.IO) {
        // Save to local database first
        val entity = FurnitureEntity.fromDomainModel(furniture)
        val localId = furnitureDao.insertFurniture(entity)

        try {
            // Attempt to sync with remote
            val dto = FurnitureDto.fromDomainModel(furniture)
            val remoteFurniture = furnitureService.createFurniture(dto).blockingGet()
            
            // Update local with remote data
            val updatedEntity = FurnitureEntity.fromDto(remoteFurniture)
            furnitureDao.updateFurniture(updatedEntity)
            
            updatedEntity.toDomainModel()
        } catch (e: Exception) {
            e.printStackTrace()
            // Return local version if remote sync fails
            entity.toDomainModel()
        }
    }

    /**
     * Updates an existing furniture listing.
     * Updates locally first, then syncs with remote.
     *
     * @param furniture Updated furniture item
     * @return Updated furniture item
     */
    suspend fun updateFurniture(furniture: Furniture): Furniture = withContext(Dispatchers.IO) {
        // Update local database first
        val entity = FurnitureEntity.fromDomainModel(furniture)
        furnitureDao.updateFurniture(entity)

        try {
            // Attempt to sync with remote
            val dto = FurnitureDto.fromDomainModel(furniture)
            val remoteFurniture = furnitureService.updateFurniture(furniture.id, dto).blockingGet()
            
            // Update local with remote data
            val updatedEntity = FurnitureEntity.fromDto(remoteFurniture)
            furnitureDao.updateFurniture(updatedEntity)
            
            updatedEntity.toDomainModel()
        } catch (e: Exception) {
            e.printStackTrace()
            // Return local version if remote sync fails
            entity.toDomainModel()
        }
    }

    /**
     * Deletes a furniture listing.
     * Deletes locally first, then syncs with remote.
     *
     * @param id ID of furniture item to delete
     */
    suspend fun deleteFurniture(id: String) = withContext(Dispatchers.IO) {
        // Delete from local database first
        furnitureDao.getFurnitureById(id).collect { entity ->
            entity?.let { furnitureDao.deleteFurniture(it) }
        }

        try {
            // Attempt to sync with remote
            furnitureService.deleteFurniture(id).blockingAwait()
        } catch (e: Exception) {
            e.printStackTrace()
            // Local deletion succeeded, log remote sync failure
        }
    }

    /**
     * Uploads an image for a furniture listing.
     * Handles image file upload and updates furniture metadata.
     *
     * @param furnitureId ID of furniture item
     * @param imageFile Image file to upload
     * @return Uploaded image URL
     */
    suspend fun uploadFurnitureImage(
        furnitureId: String,
        imageFile: File
    ): String = withContext(Dispatchers.IO) {
        try {
            // Prepare multipart request
            val requestBody = imageFile.asRequestBody("image/*".toMediaTypeOrNull())
            val part = MultipartBody.Part.createFormData(
                "image",
                imageFile.name,
                requestBody
            )

            // Upload image
            furnitureService.uploadFurnitureImage(furnitureId, part).blockingGet()
        } catch (e: Exception) {
            e.printStackTrace()
            throw e
        }
    }

    /**
     * Fetches furniture item from remote API.
     * Helper function for combining local and remote data.
     */
    private suspend fun fetchRemoteFurnitureById(id: String): Flow<Furniture?> = flow {
        try {
            val remoteFurniture = furnitureService.getFurnitureById(id).blockingGet()
            val entity = FurnitureEntity.fromDto(remoteFurniture)
            furnitureDao.updateFurniture(entity)
            emit(entity.toDomainModel())
        } catch (e: Exception) {
            e.printStackTrace()
            emit(null)
        }
    }

    /**
     * Fetches furniture list from remote API.
     * Helper function for combining local and remote data.
     */
    private suspend fun fetchRemoteFurnitureList(): Flow<List<Furniture>?> = flow {
        try {
            val remoteFurniture = furnitureService.getFurnitureList(emptyMap(), 1, 100).blockingGet()
            val entities = remoteFurniture.map { FurnitureEntity.fromDto(it) }
            entities.forEach { furnitureDao.updateFurniture(it) }
            emit(entities.map { it.toDomainModel() })
        } catch (e: Exception) {
            e.printStackTrace()
            emit(null)
        }
    }

    /**
     * Fetches nearby furniture from remote API.
     * Helper function for combining local and remote data.
     */
    private suspend fun fetchRemoteFurnitureNearLocation(
        latitude: Double,
        longitude: Double,
        radius: Double
    ): Flow<List<Furniture>?> = flow {
        try {
            val remoteFurniture = furnitureService.searchFurnitureByLocation(
                latitude,
                longitude,
                radius,
                emptyMap()
            ).blockingGet()
            val entities = remoteFurniture.map { FurnitureEntity.fromDto(it) }
            entities.forEach { furnitureDao.updateFurniture(it) }
            emit(entities.map { it.toDomainModel() })
        } catch (e: Exception) {
            e.printStackTrace()
            emit(null)
        }
    }
}