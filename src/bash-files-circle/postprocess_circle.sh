# CALCULATE AEPS WITH SEVERAL DIFFERENT WIND ROSE FIDELITY LEVELS AND WAKE MODELS

# set model parameters
nturbines_vec=(9)
boundary_radius_vec=(900) #(450 600 900 1200 1500)
ndirs_vec=(10 20 30 40 50 60 70 80 90 100 120 150 200 360)
ndirs_vec_julia=[10,20,30,40,50,60,70,80,90,100,120,150,200,360]
nspeeds_vec=(1)
nspeeds_vec_julia_directory="1"
# for i in $(seq 1 ${#nspeeds_vec_julia})
windrose=NantucketWindRose
turbine_type=NREL_5MW
wake_model_vec=(GaussYawVariableSpread) #JensenCosine)
opt_algorithm=SnoptWECAlgorithm

# set layout numbers
layout_number_start=1
layout_number_end=50

# figure parameters
aeps_fig_type=ConfidenceIntervalPlot

# calculate and plot all AEP values for the specified layouts
for nturbines in ${nturbines_vec[@]}                                    # number of turbines
do
    for boundary_radius in ${boundary_radius_vec[@]}                    # circular farm boundary radius
    do
        for wake_model in ${wake_model_vec[@]}                          # optimization wake model
        do
            for analysis_wake_model in ${wake_model_vec[@]}             # analysis wake model
            do
                aeps_file_name="final-aeps-${analysis_wake_model}.txt"

                for ndirs in ${ndirs_vec[@]}                            # number of wind directions used for optimization
                do
                    ndirs=$(printf %3s $ndirs | tr ' ' 0)

                    for nspeeds in ${nspeeds_vec[@]}                    # number of wind speeds used for optimization
                    do
                        nspeeds=$(printf %3s $nspeeds | tr ' ' 0)

                        # calculate AEP values
                        layouts_directory_path="../results/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/"
                        aeps_directory_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/"
                        aeps_file_path=$aeps_directory_path$aeps_file_name
                        julia calc_aeps.jl 360 1 $windrose $nturbines $turbine_type $analysis_wake_model $layout_number_start $layout_number_end $layouts_directory_path $aeps_directory_path $aeps_file_name  
                    done

                        # # plot all layouts overlayed on each other for a specific direction-speed fidelity combination
                        # layout_plots_directory_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                        # layout_plots_file_name="final-layouts-plot.png"
                        # julia plot_overlayed_layouts_by_direction_speed.jl $layout_number_start $layout_number_end $layouts_directory_path $layout_plots_directory_path $layout_plots_file_name
                done

                # plot AEP values
                aeps_directory_partial_path="../results/final-aeps/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                aeps_plot_directory_path="../results/figures/aep-plots/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                aeps_plot_file_name="final-aeps-${analysis_wake_model}-plot.png"
                aeps_fig_title="AEP Values for Optimized, $nturbines-turbine, Circular Wind Farm Layouts"
                julia plot_aeps.jl $ndirs_vec_julia $nspeeds_vec_julia_directory $layout_number_start $layout_number_end $aeps_directory_partial_path $aeps_file_name $aeps_plot_directory_path $aeps_plot_file_name "$aeps_fig_title" $aeps_fig_type
            done
        done
    done
done
