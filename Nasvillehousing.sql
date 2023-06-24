-- Add a new column for converted sale date
ALTER TABLE housingproject..house
ADD SaleDateConverted DATE

-- Update the SaleDate column to its converted value
UPDATE housingproject..house
SET SaleDate = CONVERT(DATE, SaleDate)

-- Update the SaleDateConverted column to its converted value
UPDATE housingproject..house
SET SaleDateConverted = SaleDate

-- Populate Property Address data

-- Select all columns from the NashvilleHousing table and order by ParcelID
SELECT *
FROM housingproject..house 
ORDER BY ParcelID

-- Join NashvilleHousing table with itself to populate missing PropertyAddress data
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) AS MergedPropertyAddress
FROM housingproject..house AS a
JOIN housingproject..house AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-- Update NashvilleHousing table with merged PropertyAddress data
UPDATE a
SET PropertyAddress = MergedPropertyAddress
FROM housingproject..house AS a
JOIN (
	-- Subquery to obtain merged PropertyAddress data
	SELECT a.ParcelID, ISNULL(a.PropertyAddress, b.PropertyAddress) AS MergedPropertyAddress
	FROM housingproject..house AS a
	JOIN housingproject..house AS b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
	WHERE a.PropertyAddress IS NULL
) AS c
	ON a.ParcelID = c.ParcelID
WHERE a.PropertyAddress IS NULL

-- Split PropertyAddress into two columns
UPDATE housingproject..house 
SET
    PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
WHERE PropertyAddress IS NOT NULL


-- Add new columns for split PropertyAddress data
ALTER TABLE housingproject..house
ADD PropertyStreetAddress NVARCHAR(255) DEFAULT NULL,
    PropertyCity NVARCHAR(255) DEFAULT NULL

-- Split OwnerAddress into three columns
UPDATE housingproject..house
SET
    OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
WHERE OwnerAddress IS NOT NULL

-- Add new columns for split OwnerAddress data
ALTER TABLE housingproject..house
ADD OwnerSplitAddress NVARCHAR(255) DEFAULT NULL,
    OwnerSplitCity NVARCHAR(255) DEFAULT NULL,
    OwnerSplitState NVARCHAR(255) DEFAULT NULL

-- Change Y and N to Yes and No in "Sold as Vacant" field
-- Show count of distinct SoldAsVacant values
SELECT SoldAsVacant, COUNT(SoldAsVacant) number
FROM housingproject..house 
GROUP BY SoldAsVacant
ORDER BY 2

-- Add constraint to enforce "Yes" or "No" values for SoldAsVacant column
ALTER TABLE housingproject..house
ADD CONSTRAINT chk_SoldAsVacant CHECK (SoldAsVacant IN ('Yes', 'No'))

-- Update SoldAsVacant values to "Yes" or "No"
UPDATE housingproject..house 
SET SoldAsVacant = CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END

-- Remove duplicates from NashvilleHousing table
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM housingproject..house a
)
SELECT *
FROM CTE
WHERE row_num = 1
ORDER BY PropertyAddress

-- Select all rows from NashvilleHousing table
SELECT *
FROM housingproject..house a
order by 1 desc

-- Delete Unused Columns

Select *
From housingproject..house 

ALTER TABLE housingproject..house
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate