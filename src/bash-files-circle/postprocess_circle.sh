# CALCULATE AEPS WITH SEVERAL DIFFERENT WIND ROSE FIDELITY LEVELS AND WAKE MODELS

export SLURM_NTASKS=1

# set what analyses to run
calculate_initial_aeps=false
calculate_aeps=false
calculate_montecarlo_aeps=false
calculate_initial_final_correlation=true
plot_layouts=false
plot_aeps=false
plot_montecarlo=false
plot_initial_final_scatter=false

# set model parameters
nturbines_vec=(16)
boundary_radius_vec=(1350)
ndirs_vec=(20 120) #(8 10 12 14 16 18 20 22 24 26 28 30 33 36 45 51 60 72 90 120 180 360)              
ndirs_vec_julia=[20,120] #[8,10,12,14,16,18,20,22,24,26,28,30,33,36,45,51,60,72,90,120,180,360]
nspeeds_vec=(1 20) #(1 5 10 20)
nspeeds_vec_julia=[1,20] #[01,05,10,20]
windrose=HornsRevWindRose
turbine_type=VestasV80_2MW
wake_model_vec=(GaussYawVariableSpread)
opt_algorithm=SnoptWECAlgorithm

# set layout numbers
layout_number_start=1
layout_number_end=200

# AEP plot parameters
aeps_fig_type=ConfidenceIntervalScatterPlot


# calculate all initial AEP values
for nturbines in ${nturbines_vec[@]}                                    # number of turbines
do
    for boundary_radius in ${boundary_radius_vec[@]}                    # circular farm boundary radius
    do
        if $calculate_initial_aeps == true
        then

            if $calculate_montecarlo_aeps == true
            then
                aeps_file_name="montecarlo-initial-aeps-GaussYawVariableSpread.txt"
            else
                aeps_file_name="intial-aeps-GaussYawVariableSpread.txt"
            fi
            
            # calculate AEP values for initial layouts
            initial_layouts_directory_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/"
            initial_aeps_directory_path="../data/initial-aeps/circle/${nturbines}turb/${boundary_radius}r/"
            parallel_processing=true
            julia calc_aeps.jl \
                360 \
                25 \
                $windrose \
                $nturbines \
                $turbine_type \
                GaussYawVariableSpread \
                $layout_number_start \
                $layout_number_end \
                $initial_layouts_directory_path \
                $initial_aeps_directory_path \
                $aeps_file_name \
                $parallel_processing \
                initial_layout
        fi
    done
done


# calculate and plot all final AEP values for the specified layouts
for nturbines in ${nturbines_vec[@]}                                    # number of turbines
do
    for boundary_radius in ${boundary_radius_vec[@]}                    # circular farm boundary radius
    do
        for wake_model in ${wake_model_vec[@]}                          # optimization wake model
        do
            for analysis_wake_model in ${wake_model_vec[@]}             # analysis wake model
            do
                if $calculate_montecarlo_aeps == true
                then
                    aeps_file_name="montecarlo-final-aeps-${analysis_wake_model}.txt"
                else
                    aeps_file_name="final-aeps-${analysis_wake_model}.txt"
                fi

                for ndirs in ${ndirs_vec[@]}                            # number of wind directions used for optimization
                do
                    ndirs=$(printf %3s $ndirs | tr ' ' 0)

                    for nspeeds in ${nspeeds_vec[@]}                    # number of wind speeds used for optimization
                    do
                        nspeeds=$(printf %2s $nspeeds | tr ' ' 0)

                        if $calculate_aeps == true
                        then

                            # calculate AEP values for final layouts
                            layouts_directory_path="../results/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                            aeps_directory_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                            aeps_file_path=$aeps_directory_path$aeps_file_name
                            parallel_processing=true
                            julia calc_aeps.jl \
                                360 \
                                25 \
                                $windrose \
                                $nturbines \
                                $turbine_type \
                                $analysis_wake_model \
                                $layout_number_start \
                                $layout_number_end \
                                $layouts_directory_path \
                                $aeps_directory_path \
                                $aeps_file_name \
                                $parallel_processing
                                final_layout
                        fi
                    done

                    if $plot_layouts == true
                    then
                        # plot all layouts overlayed on each other for a specific direction-speed fidelity combination
                        layout_plots_directory_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                        layout_plots_file_name="final-layouts-plot.png"
                        julia plot_overlayed_layouts_by_direction_speed.jl $layout_number_start $layout_number_end $layouts_directory_path $layout_plots_directory_path $layout_plots_file_name
                    fi
                done

                if $plot_aeps == true
                then
                    # plot AEP values
                    aeps_directory_partial_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                    aeps_plot_directory_path="../results/figures/aep-plots/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                    aeps_plot_file_name="final-aeps-${analysis_wake_model}-plot.png"
                    aeps_fig_title="AEP Values for Optimized, $nturbines-turbine, Circular Wind Farm Layouts"
                    julia plot_aeps.jl \
                        $ndirs_vec_julia \
                        $nspeeds_vec_julia \
                        $analysis_wake_model \
                        $layout_number_start \
                        $layout_number_end \
                        $aeps_directory_partial_path \
                        $aeps_file_name \
                        $aeps_plot_directory_path \
                        "$aeps_fig_title" \
                        $aeps_fig_type \
                        $nturbines \
                        $boundary_radius

                fi
                
                if $plot_montecarlo == true
                then
                    # plot Monte Carlo results
                    aeps_directory_partial_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                    montecarlo_plot_directory_path="../results/figures/aep-plots/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/reanalyzed-with-${analysis_wake_model}/"
                    aeps_fig_title=""
                    max_aeps_file_path="../results/final-aeps/circle/max_aep_circle.yaml"
                    julia plot_montecarlo.jl \
                        $ndirs_vec_julia \
                        $nspeeds_vec_julia \
                        $analysis_wake_model \
                        $layout_number_start \
                        $layout_number_end \
                        $aeps_directory_partial_path \
                        "montecarlo-final-aeps-${analysis_wake_model}.txt" \
                        $montecarlo_plot_directory_path \
                        $nturbines \
                        $boundary_radius
                fi 

                if $plot_initial_final_scatter == true
                then
                    initial_aeps_directory_path="../data/initial-aeps/circle/${nturbines}turb/${boundary_radius}r/"
                    final_aeps_directory_partial_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                    scatter_plot_directory_path="../results/figures/aep-plots/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/reanalyzed-with-${analysis_wake_model}/"
                    aeps_fig_title=""
                    max_aeps_file_path="../results/final-aeps/circle/max_aep_circle.yaml"
                    julia plot_initial_final_aep_scatter.jl \
                        $ndirs_vec_julia \
                        $nspeeds_vec_julia \
                        $analysis_wake_model \
                        $layout_number_start \
                        $layout_number_end \
                        $initial_aeps_directory_path \
                        $final_aeps_directory_partial_path \
                        "montecarlo-initial-aeps-${analysis_wake_model}.txt" \
                        "montecarlo-final-aeps-${analysis_wake_model}.txt" \
                        $scatter_plot_directory_path \
                        $nturbines \
                        $boundary_radius
                fi

                if $calculate_initial_final_correlation == true
                then
                    initial_aeps_directory_path="../data/initial-aeps/circle/${nturbines}turb/${boundary_radius}r/"
                    final_aeps_directory_partial_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                    julia calc_initial_final_aep_cor.jl \
                        $ndirs_vec_julia \
                        $nspeeds_vec_julia \
                        $analysis_wake_model \
                        $layout_number_start \
                        $layout_number_end \
                        $initial_aeps_directory_path \
                        $final_aeps_directory_partial_path \
                        "montecarlo-initial-aeps-${analysis_wake_model}.txt" \
                        "montecarlo-final-aeps-${analysis_wake_model}.txt" \
                        $nturbines \
                        $boundary_radius
                fi

            done
        done
    done
done





# # CALCULATE AEPS WITH SEVERAL DIFFERENT WIND ROSE FIDELITY LEVELS AND WAKE MODELS

# # set what analyses to run
# calculate_aeps=true
# plot_layouts=false
# plot_aeps=false
# plot_montecarlo=false

# # set model parameters
# nturbines_vec=(80)
# ndirs_vec=(12 36 72 120 360)
# ndirs_vec_julia=[12,36,72,120,360]
# nspeeds_vec=(1 5 10 15 20 25)
# nspeeds_vec_julia=[01,05,10,15,20,25]
# windrose=HornsRevWindRose
# turbine_type=VestasV80_2MW
# wake_model_vec=(JensenCosine) #(GaussYawVariableSpread)
# opt_algorithm=SnoptWECAlgorithm

# # set layout numbers
# layout_number_start=1
# layout_number_end=20

# # AEP plot parameters
# aeps_fig_type=ConfidenceIntervalScatterPlot

# # Monte Carlo plot parameters
# sample_sizes=[]

# # calculate and plot all AEP values for the specified layouts
# for nturbines in ${nturbines_vec[@]}                                    # number of turbines
# do
#     for wake_model in ${wake_model_vec[@]}                          # optimization wake model
#     do
#         for analysis_wake_model in JensenCosine GaussYawVariableSpread #${wake_model_vec[@]}             # analysis wake model
#         do
#             aeps_file_name="final-aeps-${analysis_wake_model}.txt"

#             for ndirs in ${ndirs_vec[@]}                            # number of wind directions used for optimization
#             do
#                 ndirs=$(printf %3s $ndirs | tr ' ' 0)

#                 for nspeeds in ${nspeeds_vec[@]}                    # number of wind speeds used for optimization
#                 do
#                     nspeeds=$(printf %2s $nspeeds | tr ' ' 0)

#                     if $calculate_aeps == true
#                     then
#                         # calculate AEP values
#                         layouts_directory_path="../results/final-layouts/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
#                         aeps_directory_path="../results/final-aeps/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
#                         aeps_file_path=$aeps_directory_path$aeps_file_name
#                         julia calc_aeps.jl \
#                             360 \
#                             25 \
#                             $windrose \
#                             $nturbines \
#                             $turbine_type \
#                             $analysis_wake_model \
#                             $layout_number_start \
#                             $layout_number_end \
#                             $layouts_directory_path \
#                             $aeps_directory_path \
#                             $aeps_file_name
#                     fi
#                 done

#                 if $plot_layouts == true
#                 then
#                     # plot all layouts overlayed on each other for a specific direction-speed fidelity combination
#                     layout_plots_directory_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
#                     layout_plots_file_name="final-layouts-plot.png"
#                     julia plot_overlayed_layouts_by_direction_speed.jl $layout_number_start $layout_number_end $layouts_directory_path $layout_plots_directory_path $layout_plots_file_name
#                 fi
#             done

#             if $plot_aeps == true
#             then
#                 # plot AEP values
#                 aeps_directory_partial_path="../results/final-aeps/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
#                 aeps_plot_directory_path="../results/figures/aep-plots/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/reanalyzed-with-${analysis_wake_model}/"
#                 aeps_fig_title="AEP Values for Optimized, $nturbines-turbine, Horns Rev Wind Farm Layouts"
#                 julia plot_aeps.jl \
#                     $ndirs_vec_julia \
#                     $nspeeds_vec_julia \
#                     $analysis_wake_model \
#                     $layout_number_start \
#                     $layout_number_end \
#                     $aeps_directory_partial_path \
#                     $aeps_file_name \
#                     $aeps_plot_directory_path \
#                     "$aeps_fig_title" \
#                     $aeps_fig_type
#             fi

#             if $plot_montecarlo == true
#             then
#                 # plot Monte Carlo results
#                 aeps_directory_partial_path="../results/final-aeps/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
#                 montecarlo_plot_directory_path="../results/figures/aep-plots/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/reanalyzed-with-${analysis_wake_model}/"
#                 aeps_fig_title=""
#                 julia plot_montecarlo.jl \
#                     $ndirs_vec_julia \
#                     $nspeeds_vec_julia \
#                     $analysis_wake_model \
#                     $layout_number_start \
#                     $layout_number_end \
#                     $aeps_directory_partial_path \
#                     $aeps_file_name \
#                     $montecarlo_plot_directory_path
#             fi 
#         done
#     done
# done


