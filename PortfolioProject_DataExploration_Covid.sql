-- Fetch data from CovidDeaths table
SELECT
    location, date, total_cases, new_cases, total_deaths, population
FROM
    PortfolioProject..CovidDeaths
ORDER BY
    1, 2;

-- Calculate percentage of deaths in cases
SELECT
    location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS percentage_of_deaths
FROM
    PortfolioProject..CovidDeaths
ORDER BY
    1, 2;

-- Calculate percentage of cases in population
SELECT
    location, date, total_cases, population, (total_cases / population) * 100 AS percentage_of_cases
FROM
    PortfolioProject..CovidDeaths
WHERE
    date = '2021-03-04 00:00:00.000'
ORDER BY
    5 DESC;

-- Find countries with the highest infection rate compared to population
SELECT
    location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population) * 100) AS percentage_of_infectedPopulation
FROM
    PortfolioProject..CovidDeaths
GROUP BY
    location, population
ORDER BY
    4 DESC;

-- Find countries with the highest death count per population
SELECT
    location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC;

-- Identify continents with the highest death count
SELECT
    continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    continent
ORDER BY
    TotalDeathCount DESC;

-- Calculate global numbers by date
SELECT
    date, SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    date
ORDER BY
    1, 2;

-- Calculate overall global numbers
SELECT
    SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent IS NOT NULL;


-- Combine both tables: CovidDeaths and CovidVaccinations
-- Calculate the rolling total vaccinations for each location and date
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
    -- ,(RollingTotalVaccinations / population) * 100 -- We need to use a common table expression or temp table to use RollingTotalVaccinations
FROM
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;


-- Calculate RollingTotalVaccinations percentage from population
-- Using Common Table Expression
WITH RollingTotalVaccinationsTable AS (
    SELECT
        dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
    FROM
        PortfolioProject..CovidDeaths dea  
    JOIN
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT
    *, (RollingTotalVaccinations / population) * 100 AS TotalVaccinationPercentage
FROM
    RollingTotalVaccinationsTable;


-- Calculate RollingTotalVaccinations percentage from population
-- Using Temp Tables

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS #RollingTotalVaccinationsTable

-- Create the temporary table
CREATE TABLE #RollingTotalVaccinationsTable (
    continent VARCHAR(50),
    location VARCHAR(50),
    date datetime,
    population INT,
    new_vaccinations INT,
    RollingTotalVaccinations INT
)

-- Populate the temporary table
INSERT INTO #RollingTotalVaccinationsTable
SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
    -- (RollingTotalVaccinations / population) * 100 -- We need to use a common table expression or temp table to use RollingTotalVaccinations
FROM
    PortfolioProject..CovidDeaths dea  
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL

-- Retrieve data from the temporary table
SELECT * FROM #RollingTotalVaccinationsTable

-- Add a new column to the temporary table
ALTER TABLE #RollingTotalVaccinationsTable ADD TotalVaccinationPercentage FLOAT

-- Calculate the vaccination percentage and update the temporary table
UPDATE #RollingTotalVaccinationsTable
SET TotalVaccinationPercentage = (population / RollingTotalVaccinations) * 100

-- Fetch data from the updated temporary table
SELECT *, (RollingTotalVaccinations / population) * 100 AS TotalVaccinationPercentage
FROM #RollingTotalVaccinationsTable;



-- Create a view to calculate total vaccinations and percentages
CREATE VIEW PercentagePopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM
    PortfolioProject..CovidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

-- Fetch data from the view
SELECT * FROM PercentagePopulationVaccinated;

